import IORedis from "ioredis";
import { env } from "../config/env";

// Shared ioredis connection for BullMQ. Workers/QueueEvents require
// `maxRetriesPerRequest: null` (BullMQ uses blocking commands that must not be
// aborted by ioredis' per-request retry cap).
//
// Singleton across `--hot` reloads via globalThis, mirroring src/lib/prisma.ts,
// so we don't leak a new TCP connection on every reload.
const globalForRedis = globalThis as unknown as { redis?: IORedis };

export const redisConnection =
  globalForRedis.redis ??
  new IORedis(env.REDIS_URL, {
    maxRetriesPerRequest: null,
  });

if (!env.isProduction) globalForRedis.redis = redisConnection;
