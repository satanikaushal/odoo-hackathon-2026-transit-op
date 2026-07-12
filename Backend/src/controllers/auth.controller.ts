import type { Request, Response } from "express";
import { ok } from "../lib/response";
import { reqLogger } from "../lib/logger";
import { authService } from "../services/auth.service";
import type { LoginInput, RefreshInput } from "../schemas/auth.schema";

export async function login(req: Request, res: Response) {
  const input = req.validated.body as LoginInput;
  const result = await authService.login(input, {
    ipAddress: req.ip ?? null,
    userAgent: req.get("user-agent") ?? null,
  });
  // Never log the password or the issued tokens — only who authenticated.
  reqLogger(req).info(
    { userId: result.user.id, role: result.user.role },
    "login succeeded",
  );
  ok(res, result);
}

export async function refresh(req: Request, res: Response) {
  const { refreshToken } = req.validated.body as RefreshInput;
  const result = await authService.refresh(refreshToken);
  reqLogger(req).info("access token refreshed (refresh token rotated)");
  ok(res, result);
}

export async function logout(req: Request, res: Response) {
  const { refreshToken } = req.validated.body as RefreshInput;
  await authService.logout(refreshToken);
  reqLogger(req).info("logout succeeded; refresh token revoked");
  res.status(204).send();
}

export async function me(req: Request, res: Response) {
  const user = await authService.me(req.user!.sub);
  reqLogger(req).debug({ userId: req.user!.sub }, "fetched current user");
  ok(res, user);
}
