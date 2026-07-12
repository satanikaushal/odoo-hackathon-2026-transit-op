import { z } from "zod";

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
