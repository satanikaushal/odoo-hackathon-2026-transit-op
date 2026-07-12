import { randomUUID } from "node:crypto";
import express from "express";
import helmet from "helmet";
import pinoHttp from "pino-http";
import { logger } from "./lib/logger";
import { router } from "./routes";
import { notFound } from "./middleware/notFound";
import { errorHandler } from "./middleware/errorHandler";
import { globalRateLimiter } from "./middleware/rateLimit";

export function createApp() {
  const app = express();

  app.disable("x-powered-by");
  // Secure HTTP response headers (HSTS, X-Content-Type-Options, X-Frame-Options,
  // a baseline CSP, etc.). Runs first so every response is covered.
  app.use(helmet());
  // Trust the first proxy hop so req.ip reflects the real client (behind a
  // load balancer / reverse proxy) rather than the proxy's address. This is
  // what the rate limiter keys on. Only trust as many hops as you actually run
  // in front of the app — over-trusting lets clients spoof X-Forwarded-For.
  app.set("trust proxy", 1);
  app.use(
    pinoHttp({
      logger,
      // Correlate every log line for a request. Honour an inbound
      // X-Request-Id (e.g. from a gateway) and echo the id back on the response.
      genReqId: (req, res) => {
        const inbound = req.headers["x-request-id"];
        const id = (Array.isArray(inbound) ? inbound[0] : inbound) ?? randomUUID();
        res.setHeader("x-request-id", id);
        return id;
      },
      // 5xx → error, 4xx → warn, everything else → info.
      customLogLevel: (_req, res, err) => {
        if (err || res.statusCode >= 500) return "error";
        if (res.statusCode >= 400) return "warn";
        return "info";
      },
      // Stamp the authenticated principal onto the access log. `req.user` is set
      // by the authenticate middleware, which runs before the response finishes,
      // so it is populated by the time this request is logged.
      customProps: (req) => {
        const user = (req as { user?: { sub: string; role: string } }).user;
        return user ? { userId: user.sub, role: user.role } : {};
      },
      serializers: {
        req: (req) => ({ method: req.method, url: req.url }),
        res: (res) => ({ statusCode: res.statusCode }),
      },
      customSuccessMessage: (req, res) => `${req.method} ${req.url} ${res.statusCode}`,
      customErrorMessage: (req, res, err) => `${req.method} ${req.url} ${res.statusCode} - ${err.message}`,
    }),
  );
  // Whole-API rate limit, before body parsing so flooded requests are cheap to
  // reject. Runs after pino-http so 429s are still logged.
  app.use(globalRateLimiter);
  // Cap request body size to blunt large-payload DoS. All endpoints take small
  // JSON bodies; 100kb is generous. Oversized bodies get a 413.
  app.use(express.json({ limit: "100kb" }));
  app.use(router);

  app.use(notFound);
  app.use(errorHandler);

  return app;
}
  