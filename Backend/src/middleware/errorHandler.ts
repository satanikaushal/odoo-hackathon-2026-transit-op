import type { NextFunction, Request, Response } from "express";
import { Prisma } from "../generated/prisma/client";
import { ApiError } from "../lib/ApiError";
import { logger } from "../lib/logger";

// Central fallback mapping for Prisma errors (PLAN.md §9.2) so services don't
// each repeat try/catch. A service may still catch a code itself when it can
// say something more useful (e.g. vehicle delete → "retire it instead").
// Violated columns: classic engines put them on meta.target; driver adapters
// (our @prisma/adapter-pg setup) nest them under driverAdapterError, with the
// pg-style quotes still embedded.
function uniqueViolationFields(meta: Record<string, unknown> | undefined): string {
  const adapterFields = (meta as { driverAdapterError?: { cause?: { constraint?: { fields?: string[] } } } })
    ?.driverAdapterError?.cause?.constraint?.fields;
  const target = adapterFields ?? meta?.target;
  if (Array.isArray(target)) return target.map((f) => String(f).replaceAll('"', "")).join(", ");
  return typeof target === "string" ? target : "value";
}

function fromPrismaError(err: Prisma.PrismaClientKnownRequestError): ApiError | null {
  switch (err.code) {
    case "P2002":
      return ApiError.conflict(`A record with this ${uniqueViolationFields(err.meta)} already exists`);
    case "P2025":
      return ApiError.notFound("Resource not found");
    case "P2003":
      return ApiError.conflict("Operation blocked by related records");
    default:
      return null;
  }
}

export function errorHandler(err: unknown, req: Request, res: Response, _next: NextFunction) {
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    const mapped = fromPrismaError(err);
    if (mapped) err = mapped;
  }

  if (err instanceof ApiError) {
    logger.warn({ details: err.details, url: req.originalUrl }, err.message);
    return res.status(err.statusCode).json({ success: false, message: err.message, details: err.details });
  }

  logger.error({ err, url: req.originalUrl }, "unhandled error");
  return res.status(500).json({ success: false, message: "Internal server error" });
}
