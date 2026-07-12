const NODE_ENV = process.env.NODE_ENV ?? "development";

function required(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required env var: ${name}`);
  return value;
}

export const env = {
  NODE_ENV,
  PORT: Number(process.env.PORT ?? 3000),
  isProduction: NODE_ENV === "production",
  DATABASE_URL: required("DATABASE_URL"),
  JWT_ACCESS_SECRET: required("JWT_ACCESS_SECRET"),
  JWT_ACCESS_TTL: process.env.JWT_ACCESS_TTL ?? "15m",
  JWT_REFRESH_TTL_DAYS: Number(process.env.JWT_REFRESH_TTL_DAYS ?? 7),

  // Background jobs (BullMQ). Set ENABLE_JOBS=false to disable the worker/scheduler
  // (e.g. in test runs or web-only deployments).
  ENABLE_JOBS: (process.env.ENABLE_JOBS ?? "true") !== "false",
  REDIS_URL: process.env.REDIS_URL ?? "redis://localhost:6379",

  // Rate limiting (Redis-backed). Set RATE_LIMIT_ENABLED=false to disable it
  // globally (e.g. in tests). The global limiter guards every request; the auth
  // limiter is a tighter cap on login/refresh to blunt credential brute-forcing.
  RATE_LIMIT_ENABLED: (process.env.RATE_LIMIT_ENABLED ?? "true") !== "false",
  RATE_LIMIT_WINDOW_MS: Number(process.env.RATE_LIMIT_WINDOW_MS ?? 60_000), // 1 minute
  RATE_LIMIT_MAX: Number(process.env.RATE_LIMIT_MAX ?? 120), // per window, per IP
  AUTH_RATE_LIMIT_WINDOW_MS: Number(process.env.AUTH_RATE_LIMIT_WINDOW_MS ?? 60_000),
  AUTH_RATE_LIMIT_MAX: Number(process.env.AUTH_RATE_LIMIT_MAX ?? 10),

  // License-expiry reminders.
  LICENSE_REMINDER_DAYS: Number(process.env.LICENSE_REMINDER_DAYS ?? 30),
  // Cron expression for the daily scan. Default: 08:00 every day.
  LICENSE_REMINDER_CRON: process.env.LICENSE_REMINDER_CRON ?? "0 8 * * *",

  // SMTP mail transport. When unset the mailer no-ops (logs the message it would
  // have sent) so local/dev runs don't fail without a mail server.
  SMTP_HOST: process.env.SMTP_HOST,
  SMTP_PORT: Number(process.env.SMTP_PORT ?? 587),
  SMTP_SECURE: process.env.SMTP_SECURE === "true",
  SMTP_USER: process.env.SMTP_USER,
  SMTP_PASS: process.env.SMTP_PASS,
  MAIL_FROM: process.env.MAIL_FROM ?? "TransitOps <no-reply@transitops.local>",
};
