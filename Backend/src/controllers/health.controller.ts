import type { Request, Response } from "express";
import { ok } from "../lib/response";

const startedAt = process.hrtime.bigint();

export function getHealth(_req: Request, res: Response) {
  const uptimeSeconds = Number(process.hrtime.bigint() - startedAt) / 1e9;
  return ok(res, {
    status: "ok",
    uptime: uptimeSeconds,
    timestamp: new Date().toISOString(),
  });
}
