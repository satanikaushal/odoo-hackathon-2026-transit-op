import type { NextFunction, Request, Response } from "express";
import { ApiError } from "../lib/ApiError";

export function notFound(req: Request, _res: Response, next: NextFunction) {
  next(ApiError.notFound(`Route ${req.originalUrl} not found`));
}
