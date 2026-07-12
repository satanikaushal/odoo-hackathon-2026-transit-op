import type { Response } from "express";

export function ok<T>(res: Response, data: T, status = 200, message = "OK") {
  return res.status(status).json({ success: true, message, data });
}

export function created<T>(res: Response, data: T, message = "Created") {
  return ok(res, data, 201, message);
}
