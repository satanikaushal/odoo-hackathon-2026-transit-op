import { prisma } from "../lib/prisma";
import { ApiError } from "../lib/ApiError";
import { env } from "../config/env";
import { getAccessTokenExpiry, signAccessToken } from "../lib/jwt";
import { generateRefreshToken, hashRefreshToken } from "../lib/refreshToken";
import type { LoginInput } from "../schemas/auth.schema";
import type { DeviceType, Role } from "../generated/prisma/client";
import { logger } from "../lib/logger";

const INVALID_CREDENTIALS = "Invalid email or password";

// Lock an account after this many consecutive failed login attempts.
const MAX_FAILED_LOGIN_ATTEMPTS = 5;
// How long the account stays locked once the threshold is reached.
const LOCKOUT_DURATION_MS = 15 * 60 * 1000; // 15 minutes

interface DeviceInfo {
  deviceType?: DeviceType | null;
  deviceToken?: string | null;
}

function refreshExpiry(): Date {
  return new Date(Date.now() + env.JWT_REFRESH_TTL_DAYS * 24 * 60 * 60 * 1000);
}

async function issueTokens(userId: string, role: Role, device: DeviceInfo = {}) {
  const accessToken = signAccessToken({ sub: userId, role });
  const refreshToken = generateRefreshToken();
  const refreshTokenExpiresAt = refreshExpiry();

  await prisma.refreshToken.create({
    data: {
      userId,
      tokenHash: hashRefreshToken(refreshToken),
      expiresAt: refreshTokenExpiresAt,
      deviceType: device.deviceType ?? null,
      deviceToken: device.deviceToken ?? null,
    },
  });

  return {
    accessToken,
    accessTokenExpiresAt: getAccessTokenExpiry(accessToken),
    refreshToken,
    refreshTokenExpiresAt,
  };
}

export const authService = {
  async login({ email, password, deviceType, deviceToken }: LoginInput) {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !user.isActive) throw ApiError.unauthorized(INVALID_CREDENTIALS);

    // Account is currently locked out due to too many failed attempts.
    if (user.lockedUntil && user.lockedUntil > new Date()) {
      logger.warn({
        message: "Login attempt on locked account",
        userId: user.id,
        email: user.email,
        lockedUntil: user.lockedUntil,
      });
      throw ApiError.forbidden(
        "Account temporarily locked due to too many failed login attempts. Please try again later.",
      );
    }

    logger.info({
      message: "User login attempt",
      userId: user.id,
      email: user.email,
      deviceType,
      deviceToken,
    });

    // TODO: Send a email notification to the user if the login is from a new device or location.

    const validPassword = await Bun.password.verify(password, user.passwordHash);
    if (!validPassword) {
      const attempts = user.failedLoginAttempts + 1;
      const shouldLock = attempts >= MAX_FAILED_LOGIN_ATTEMPTS;

      await prisma.user.update({
        where: { id: user.id },
        data: {
          failedLoginAttempts: attempts,
          lockedUntil: shouldLock ? new Date(Date.now() + LOCKOUT_DURATION_MS) : null,
        },
      });

      if (shouldLock) {
        logger.warn({
          message: "Account locked after too many failed login attempts",
          userId: user.id,
          email: user.email,
          attempts,
        });
        // TODO: Send a security email notifying the user that their account was
        // locked due to repeated failed login attempts (include time, IP, device).
        throw ApiError.forbidden(
          "Account temporarily locked due to too many failed login attempts. Please try again later.",
        );
      }

      throw ApiError.badRequest(INVALID_CREDENTIALS);
    }

    // Successful login — clear any accumulated failed-attempt state.
    if (user.failedLoginAttempts > 0 || user.lockedUntil) {
      await prisma.user.update({
        where: { id: user.id },
        data: { failedLoginAttempts: 0, lockedUntil: null },
      });
    }

    const tokens = await issueTokens(user.id, user.role, { deviceType, deviceToken });
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

    // Rotate: revoke the used token and issue a fresh pair, carrying the device info forward.
    await prisma.refreshToken.update({ where: { id: stored.id }, data: { revokedAt: new Date() } });
    return issueTokens(stored.user.id, stored.user.role, {
      deviceType: stored.deviceType,
      deviceToken: stored.deviceToken,
    });
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
