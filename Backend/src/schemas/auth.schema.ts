import { z } from "zod";

// Strong-password policy for any endpoint that SETS a password (user creation,
// password change / reset). Deliberately NOT used by loginSchema below: login
// must accept whatever was previously stored, and applying the policy there
// would both leak it to attackers and lock out any pre-existing weaker password.
export const passwordSchema = z
  .string()
  .min(12, "Password must be at least 12 characters")
  .max(128, "Password must be at most 128 characters")
  .regex(/[a-z]/, "Password must contain a lowercase letter")
  .regex(/[A-Z]/, "Password must contain an uppercase letter")
  .regex(/[0-9]/, "Password must contain a number")
  .regex(/[^A-Za-z0-9]/, "Password must contain a symbol");

export const loginSchema = z
  .object({
    email: z.email(),
    password: z.string().min(1),
    deviceType: z.enum(["ANDROID", "IOS"]).optional(),
    deviceToken: z.string().min(1).optional(),
  })
  .refine((data) => !!data.deviceType === !!data.deviceToken, {
    message: "deviceType and deviceToken must be provided together",
    path: ["deviceToken"],
  });
export type LoginInput = z.infer<typeof loginSchema>;

export const refreshSchema = z.object({
  refreshToken: z.string().min(1),
});
export type RefreshInput = z.infer<typeof refreshSchema>;
