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
};
