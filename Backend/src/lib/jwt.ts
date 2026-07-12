import jwt from "jsonwebtoken";
import { env } from "../config/env";
import type { Role } from "../generated/prisma/client";

export interface AccessTokenPayload {
  sub: string;
  role: Role;
}

export function signAccessToken(payload: AccessTokenPayload): string {
  return jwt.sign(payload, env.JWT_ACCESS_SECRET, { expiresIn: env.JWT_ACCESS_TTL as jwt.SignOptions["expiresIn"] });
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  return jwt.verify(token, env.JWT_ACCESS_SECRET) as AccessTokenPayload;
}

export function getAccessTokenExpiry(token: string): Date {
  const { exp } = jwt.decode(token) as { exp: number };
  return new Date(exp * 1000);
}
