import { prisma } from "../lib/prisma";
import { ApiError } from "../lib/ApiError";
import { env } from "../config/env";
import { getAccessTokenExpiry, signAccessToken } from "../lib/jwt";
import { generateRefreshToken, hashRefreshToken } from "../lib/refreshToken";
import type { LoginInput } from "../schemas/auth.schema";
import type { DeviceType, Role, User } from "../generated/prisma/client";
import { logger } from "../lib/logger";
import { mailer } from "../lib/mailer";

const INVALID_CREDENTIALS = "Invalid email or password";

// Lock an account after this many consecutive failed login attempts.
const MAX_FAILED_LOGIN_ATTEMPTS = 5;
// How long the account stays locked once the threshold is reached.
const LOCKOUT_DURATION_MS = 15 * 60 * 1000; // 15 minutes

// Everything we know about where/how a session was created. Persisted on the
// refresh token so a later login can be compared against past ones.
interface SessionContext {
  deviceType?: DeviceType | null;
  deviceToken?: string | null;
  ipAddress?: string | null;
  userAgent?: string | null;
}

// Request-derived context the controller passes through to login().
export interface LoginContext {
  ipAddress?: string | null;
  userAgent?: string | null;
}

function refreshExpiry(): Date {
  return new Date(Date.now() + env.JWT_REFRESH_TTL_DAYS * 24 * 60 * 60 * 1000);
}

async function issueTokens(userId: string, role: Role, session: SessionContext = {}) {
  const accessToken = signAccessToken({ sub: userId, role });
  const refreshToken = generateRefreshToken();
  const refreshTokenExpiresAt = refreshExpiry();

  await prisma.refreshToken.create({
    data: {
      userId,
      tokenHash: hashRefreshToken(refreshToken),
      expiresAt: refreshTokenExpiresAt,
      deviceType: session.deviceType ?? null,
      deviceToken: session.deviceToken ?? null,
      ipAddress: session.ipAddress ?? null,
      userAgent: session.userAgent ?? null,
    },
  });

  return {
    accessToken,
    accessTokenExpiresAt: getAccessTokenExpiry(accessToken),
    refreshToken,
    refreshTokenExpiresAt,
  };
}

interface LoginNovelty {
  newDevice: boolean;
  newLocation: boolean;
}

// Two sessions are "the same device" if they share a push token (mobile) or,
// lacking that, a user-agent (web). If we have no fingerprint for the current
// login at all, we can't call the device new — so we don't.
function isSameDevice(
  prior: { deviceToken: string | null; userAgent: string | null },
  session: SessionContext,
): boolean {
  if (session.deviceToken) return prior.deviceToken === session.deviceToken;
  if (session.userAgent) return prior.userAgent === session.userAgent;
  return true;
}

// Compare this login against the user's past sessions. Must be called BEFORE
// the new refresh token is created, so the current session isn't matched
// against itself. A user's very first login is never treated as novel.
async function detectLoginNovelty(userId: string, session: SessionContext): Promise<LoginNovelty> {
  const priorSessions = await prisma.refreshToken.findMany({
    where: { userId },
    select: { deviceToken: true, userAgent: true, ipAddress: true },
  });

  if (priorSessions.length === 0) return { newDevice: false, newLocation: false };

  const canFingerprintDevice = Boolean(session.deviceToken || session.userAgent);
  const newDevice = canFingerprintDevice
    ? !priorSessions.some((s) => isSameDevice(s, session))
    : false;

  const newLocation = session.ipAddress
    ? !priorSessions.some((s) => s.ipAddress === session.ipAddress)
    : false;

  return { newDevice, newLocation };
}

// Notify the user that their account was just signed into from somewhere new.
// Best-effort: never throws into the login path (the caller fire-and-forgets),
// and in dev the mailer just logs (see lib/mailer.ts).
async function sendNewLoginEmail(
  user: Pick<User, "email" | "name">,
  session: SessionContext,
  novelty: LoginNovelty,
): Promise<void> {
  const reasons: string[] = [];
  if (novelty.newDevice) reasons.push("a new device");
  if (novelty.newLocation) reasons.push("a new location");

  const subject = "New sign-in to your TransitOps account";
  const text = [
    `Hi ${user.name},`,
    "",
    `We noticed a sign-in to your TransitOps account from ${reasons.join(" and ")}.`,
    "",
    `Time:       ${new Date().toISOString()}`,
    `IP address: ${session.ipAddress ?? "unknown"}`,
    `Device:     ${session.userAgent ?? session.deviceType ?? "unknown"}`,
    "",
    "If this was you, no action is needed. If you don't recognise this activity,",
    "change your password immediately and contact your administrator.",
  ].join("\n");

  await mailer.send({ to: user.email, subject, text });
}

// Notify the user that their account was locked after too many failed login
// attempts. Best-effort, same contract as sendNewLoginEmail (never throws into
// the login path; dev mailer just logs).
async function sendAccountLockedEmail(
  user: Pick<User, "email" | "name">,
  session: SessionContext,
  lockedUntil: Date,
): Promise<void> {
  const subject = "Your TransitOps account has been locked";
  const text = [
    `Hi ${user.name},`,
    "",
    `Your TransitOps account was locked after ${MAX_FAILED_LOGIN_ATTEMPTS} consecutive`,
    "failed login attempts. It will unlock automatically at the time below.",
    "",
    `Time:        ${new Date().toISOString()}`,
    `Locked until: ${lockedUntil.toISOString()}`,
    `IP address:  ${session.ipAddress ?? "unknown"}`,
    `Device:      ${session.userAgent ?? session.deviceType ?? "unknown"}`,
    "",
    "If this was you, simply wait and try again, or reset your password. If you",
    "don't recognise this activity, change your password immediately and contact",
    "your administrator — someone may be trying to access your account.",
  ].join("\n");

  await mailer.send({ to: user.email, subject, text });
}

export const authService = {
  async login(
    { email, password, deviceType, deviceToken }: LoginInput,
    context: LoginContext = {},
  ) {
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

    const session: SessionContext = {
      deviceType,
      deviceToken,
      ipAddress: context.ipAddress,
      userAgent: context.userAgent,
    };

    logger.info({
      message: "User login attempt",
      userId: user.id,
      email: user.email,
      deviceType,
      deviceToken,
    });

    const validPassword = await Bun.password.verify(password, user.passwordHash);
    if (!validPassword) {
      const attempts = user.failedLoginAttempts + 1;
      const shouldLock = attempts >= MAX_FAILED_LOGIN_ATTEMPTS;
      const lockedUntil = shouldLock ? new Date(Date.now() + LOCKOUT_DURATION_MS) : null;

      await prisma.user.update({
        where: { id: user.id },
        data: { failedLoginAttempts: attempts, lockedUntil },
      });

      if (shouldLock && lockedUntil) {
        logger.warn({
          message: "Account locked after too many failed login attempts",
          userId: user.id,
          email: user.email,
          attempts,
        });
        // Notify the user their account was locked. Fire-and-forget so a slow or
        // failing mail send doesn't change the response the attacker sees.
        void sendAccountLockedEmail(user, session, lockedUntil).catch((err) =>
          logger.error({ err, userId: user.id }, "failed to send account-locked notification"),
        );
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

    // Check novelty BEFORE issuing the token, so the new session isn't compared
    // against itself.
    const novelty = await detectLoginNovelty(user.id, session);

    const tokens = await issueTokens(user.id, user.role, session);

    // Notify on a new device / location. Fire-and-forget: a slow or failing
    // mail send must never block or fail the login.
    if (novelty.newDevice || novelty.newLocation) {
      logger.info(
        { userId: user.id, ...novelty },
        "login from new device/location; notifying user",
      );
      void sendNewLoginEmail(user, session, novelty).catch((err) =>
        logger.error({ err, userId: user.id }, "failed to send new-login notification"),
      );
    }

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

    // Rotate: revoke the used token and issue a fresh pair, carrying the
    // device/session info forward.
    await prisma.refreshToken.update({ where: { id: stored.id }, data: { revokedAt: new Date() } });
    return issueTokens(stored.user.id, stored.user.role, {
      deviceType: stored.deviceType,
      deviceToken: stored.deviceToken,
      ipAddress: stored.ipAddress,
      userAgent: stored.userAgent,
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
