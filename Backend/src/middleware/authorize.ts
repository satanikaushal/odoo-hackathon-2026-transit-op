import type { NextFunction, Request, Response } from "express";
import { ApiError } from "../lib/ApiError";
import type { Role } from "../generated/prisma/client";

export function authorize(...roles: Role[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user) return next(ApiError.unauthorized());
    if (!roles.includes(req.user.role)) return next(ApiError.forbidden("Insufficient role permissions"));
    next();
  };
}
