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
  