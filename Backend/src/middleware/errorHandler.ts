import type { NextFunction, Request, Response } from "express";
import { ApiError } from "../lib/ApiError";
import { logger } from "../lib/logger";

export function errorHandler(err: unknown, req: Request, res: Response, _next: NextFunction) {
  if (err instanceof ApiError) {
    logger.warn({ details: err.details, url: req.originalUrl }, err.message);
    return res.status(err.statusCode).json({ success: false, message: err.message, details: err.details });
  }

  logger.error({ err, url: req.originalUrl }, "unhandled error");
  return res.status(500).json({ success: false, message: "Internal server error" });
}
