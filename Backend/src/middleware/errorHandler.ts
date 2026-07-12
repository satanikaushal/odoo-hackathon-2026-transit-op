import type { NextFunction, Request, Response } from "express";
import { ApiError } from "../lib/ApiError";
import { logger } from "../lib/logger";

export function errorHandler(err: unknown, req: Request, res: Response, _next: NextFunction) {
  if (err instanceof ApiError) {
    logger.warn({ details: err.details, url: req.originalUrl }, err.message);
    return res.status(err.statusCode).json({ success: false, message: err.message, details: err.details });
  }

  // Body-parser / http-errors style errors (e.g. a 413 from the body-size limit,
  // or a 400 on malformed JSON) carry their own 4xx status. Surface it with the
  // real code and message rather than masking a client mistake as a 500.
  const status = clientErrorStatus(err);
  if (status) {
    logger.warn({ url: req.originalUrl }, (err as Error).message);
    return res.status(status).json({ success: false, message: (err as Error).message });
  }

  logger.error({ err, url: req.originalUrl }, "unhandled error");
  return res.status(500).json({ success: false, message: "Internal server error" });
}

// Extract a 4xx status from an http-errors-style error, if present.
function clientErrorStatus(err: unknown): number | null {
  if (typeof err !== "object" || err === null) return null;
  const code = (err as { status?: unknown; statusCode?: unknown }).status
    ?? (err as { statusCode?: unknown }).statusCode;
  return typeof code === "number" && code >= 400 && code < 500 ? code : null;
}
