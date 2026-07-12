import { randomUUID } from "node:crypto";
import express from "express";
import pinoHttp from "pino-http";
import { logger } from "./lib/logger";
import { router } from "./routes";
import { notFound } from "./middleware/notFound";
import { errorHandler } from "./middleware/errorHandler";

export function createApp() {
  const app = express();

  app.disable("x-powered-by");
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
  app.use(express.json());
  app.use(router);

  app.use(notFound);
  app.use(errorHandler);

  return app;
}
  