import { prisma } from "../lib/prisma";
import { ApiError } from "../lib/ApiError";
import { env } from "../config/env";
import { signAccessToken } from "../lib/jwt";
import { generateRefreshToken, hashRefreshToken } from "../lib/refreshToken";
import type { LoginInput } from "../schemas/auth.schema";
import type { Role } from "../generated/prisma/client";

const INVALID_CREDENTIALS = "Invalid email or password";

function refreshExpiry(): Date {
  return new Date(Date.now() + env.JWT_REFRESH_TTL_DAYS * 24 * 60 * 60 * 1000);
}

async function issueTokens(userId: string, role: Role) {
  const accessToken = signAccessToken({ sub: userId, role });
  const refreshToken = generateRefreshToken();

  await prisma.refreshToken.create({
    data: {
      userId,
      tokenHash: hashRefreshToken(refreshToken),
      expiresAt: refreshExpiry(),
    },
  });

  return { accessToken, refreshToken };
}

export const authService = {
  async login({ email, password }: LoginInput) {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !user.isActive) throw ApiError.unauthorized(INVALID_CREDENTIALS);

    const validPassword = await Bun.password.verify(password, user.passwordHash);
    if (!validPassword) throw ApiError.unauthorized(INVALID_CREDENTIALS);

    const tokens = await issueTokens(user.id, user.role);
    return {
      ...tokens,
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
    };
  },

  async refresh(rawToken: string) {
    const tokenHash = hashRefreshToken(rawToken);
    const stored = await prisma.refreshToken.findUnique({
      where: { tokenHash },
      include: { user: true },
    });

    if (!stored || stored.revokedAt || stored.expiresAt < new Date() || !stored.user.isActive) {
      throw ApiError.unauthorized("Invalid or expired refresh token");
    }

    // Rotate: revoke the used token and issue a fresh pair.
    await prisma.refreshToken.update({ where: { id: stored.id }, data: { revokedAt: new Date() } });
    return issueTokens(stored.user.id, stored.user.role);
  },

  async logout(rawToken: string) {
    const tokenHash = hashRefreshToken(rawToken);
    await prisma.refreshToken.updateMany({
      where: { tokenHash, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  },

  async me(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, name: true, email: true, role: true, isActive: true, createdAt: true },
    });
    if (!user || !user.isActive) throw ApiError.unauthorized();
    return user;
  },
};
