import { z } from "zod";
import { DriverStatus } from "../generated/prisma/client";

// Shape validation only. Cross-field / DB-backed rules (unique license,
// expiry-vs-dispatch) live in the service layer per PLAN.md §4.
export const createDriverSchema = z.object({
  name: z.string().trim().min(1),
  licenseNumber: z.string().trim().min(1),
  licenseCategory: z.string().trim().min(1),
  licenseExpiryDate: z.coerce.date(),
  contactNumber: z.string().trim().min(1),
  // Optional on create; DB defaults apply when omitted (score 100, AVAILABLE).
  safetyScore: z.number().min(0).max(100).optional(),
  status: z.enum(DriverStatus).optional(),
});
export type CreateDriverInput = z.infer<typeof createDriverSchema>;

// PATCH: every field optional, but reject an empty body outright.
export const updateDriverSchema = createDriverSchema
  .partial()
  .refine((data) => Object.keys(data).length > 0, {
    message: "At least one field must be provided",
  });
export type UpdateDriverInput = z.infer<typeof updateDriverSchema>;

export const driverIdParamSchema = z.object({
  id: z.string().min(1),
});
export type DriverIdParam = z.infer<typeof driverIdParamSchema>;

export const listDriversQuerySchema = z.object({
  status: z.enum(DriverStatus).optional(),
  q: z.string().trim().min(1).optional(),
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(20),
  // Whitelisted sortable columns — never pass raw client input into orderBy.
  sortBy: z
    .enum(["createdAt", "name", "licenseExpiryDate", "safetyScore", "status"])
    .optional()
    .default("createdAt"),
  sortDir: z.enum(["asc", "desc"]).optional().default("desc"),
});
export type ListDriversQuery = z.infer<typeof listDriversQuerySchema>;
