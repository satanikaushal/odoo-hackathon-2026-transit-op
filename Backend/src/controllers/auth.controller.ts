import type { Request, Response } from "express";
import { ok } from "../lib/response";
import { authService } from "../services/auth.service";
import type { LoginInput, RefreshInput } from "../schemas/auth.schema";

export async function login(req: Request, res: Response) {
  const input = req.validated.body as LoginInput;
  const result = await authService.login(input);
  ok(res, result);
}

export async function refresh(req: Request, res: Response) {
  const { refreshToken } = req.validated.body as RefreshInput;
  const result = await authService.refresh(refreshToken);
  ok(res, result);
}

export async function logout(req: Request, res: Response) {
  const { refreshToken } = req.validated.body as RefreshInput;
  await authService.logout(refreshToken);
  res.status(204).send();
}

export async function me(req: Request, res: Response) {
  const user = await authService.me(req.user!.sub);
  ok(res, user);
}
