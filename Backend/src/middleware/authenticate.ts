import type { NextFunction, Request, Response } from "express";
import { ApiError } from "../lib/ApiError";
import { verifyAccessToken } from "../lib/jwt";

export function authenticate(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  const token = header?.startsWith("Bearer ") ? header.slice("Bearer ".length) : undefined;
  if (!token) return next(ApiError.unauthorized("Missing bearer token"));

  try {
    req.user = verifyAccessToken(token);
    next();
  } catch {
    next(ApiError.unauthorized("Invalid or expired access token"));
  }
}
