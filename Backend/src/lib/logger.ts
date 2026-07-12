import type { Request } from "express";
import pino, { type Logger } from "pino";
import { env } from "../config/env";

// Fields that must never appear in logs, wherever they occur in a logged
// object. pino redacts before any transport runs, so this holds for both the
// JSON output in production and pino-pretty in development.
const REDACT_PATHS = [
  'req.headers.authorization',
  'req.headers.cookie',
  'password',
  '*.password',
  'passwordHash',
  '*.passwordHash',
  'accessToken',
  '*.accessToken',
  'refreshToken',
  '*.refreshToken',
  'tokenHash',
  '*.tokenHash',
  'deviceToken',
  '*.deviceToken',
];

export const logger = pino({
  level: env.isProduction ? "info" : "debug",
  redact: { paths: REDACT_PATHS, censor: "[REDACTED]" },
  transport: env.isProduction
    ? undefined
    : { target: "pino-pretty", options: { colorize: true, translateTime: "HH:MM:ss" } },
});

// The request-scoped child logger attached by pino-http. It carries the request
// id (and the userId/role we add in app.ts), so domain events logged through it
// correlate with their HTTP request. Falls back to the base logger when there
// is no request context (e.g. unit tests that call a controller directly).
export function reqLogger(req: Request): Logger {
  return (req as Request & { log?: Logger }).log ?? logger;
}
