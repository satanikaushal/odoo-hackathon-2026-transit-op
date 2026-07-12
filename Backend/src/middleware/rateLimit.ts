import type { NextFunction, Request, Response } from "express";
import { redisConnection } from "../lib/redis";
import { ApiError } from "../lib/ApiError";
import { env } from "../config/env";
import { logger } from "../lib/logger";

export interface RateLimitOptions {
  // Sliding window size in milliseconds.
  windowMs: number;
  // Max requests allowed per window per key.
  max: number;
  // Redis key namespace so multiple limiters don't collide.
  prefix: string;
  // Derives the identity to limit on. Defaults to the client IP.
  keyGenerator?: (req: Request) => string;
  // Human-readable message on a 429.
  message?: string;
}

// Fixed-window counter, done atomically in one round-trip: INCR the counter and,
// on the first hit of a window, set its TTL. Returns [count, ttlMs]. Atomicity
// matters — a non-atomic INCR-then-EXPIRE can leak a key with no TTL (and thus a
// permanent block) if the process dies between the two calls.
const FIXED_WINDOW_LUA = `
local current = redis.call('INCR', KEYS[1])
if current == 1 then
  redis.call('PEXPIRE', KEYS[1], ARGV[1])
end
local ttl = redis.call('PTTL', KEYS[1])
return {current, ttl}
`;

function clientKey(req: Request): string {
  // req.ip honours Express's "trust proxy" setting; falls back to the socket
  // address. See the note in app.ts about configuring trust proxy in prod.
  return req.ip ?? req.socket.remoteAddress ?? "unknown";
}

/**
 * Redis-backed rate limiter. Returns an Express middleware.
 *
 * Fails **open**: if Redis is unreachable the request is allowed through (and
 * the error logged) rather than taking the whole API down with the cache. For a
 * security-critical limiter you may prefer to fail closed — flip the catch.
 */
export function rateLimit(options: RateLimitOptions) {
  const { windowMs, max, prefix, keyGenerator = clientKey, message } = options;

  return async function rateLimiter(req: Request, res: Response, next: NextFunction) {
    if (!env.RATE_LIMIT_ENABLED) return next();

    const key = `ratelimit:${prefix}:${keyGenerator(req)}`;

    let count: number;
    let ttlMs: number;
    try {
      const result = (await redisConnection.eval(
        FIXED_WINDOW_LUA,
        1,
        key,
        windowMs.toString(),
      )) as [number, number];
      [count, ttlMs] = result;
    } catch (err) {
      logger.error({ err, key }, "rate limiter Redis error — failing open");
      return next();
    }

    const remaining = Math.max(0, max - count);
    const resetSeconds = Math.ceil((ttlMs > 0 ? ttlMs : windowMs) / 1000);

    // Draft IETF RateLimit headers.
    res.setHeader("RateLimit-Limit", max);
    res.setHeader("RateLimit-Remaining", remaining);
    res.setHeader("RateLimit-Reset", resetSeconds);

    if (count > max) {
      res.setHeader("Retry-After", resetSeconds);
      logger.warn({ key, count, max }, "rate limit exceeded");
      return next(
        ApiError.tooManyRequests(
          message ?? "Too many requests, please try again later.",
        ),
      );
    }

    next();
  };
}

// Whole-API guard: a generous per-IP cap that stops runaway clients and crude
// floods without getting in the way of normal use.
export const globalRateLimiter = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MS,
  max: env.RATE_LIMIT_MAX,
  prefix: "global",
});

// Tighter cap for authentication endpoints (login/refresh), keyed by IP, to
// blunt credential brute-forcing. Complements the per-account lockout in
// auth.service.ts: lockout protects one account; this caps attempts from one
// source across many accounts.
export const authRateLimiter = rateLimit({
  windowMs: env.AUTH_RATE_LIMIT_WINDOW_MS,
  max: env.AUTH_RATE_LIMIT_MAX,
  prefix: "auth",
  message: "Too many authentication attempts, please try again later.",
});
