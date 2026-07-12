import { z } from "zod";
import { MaintenanceStatus } from "../generated/prisma/client";

// Money is validated numerically but carried as a string for Decimal precision
// (mirrors vehicle.schema's `money`).
const money = z.coerce
  .number({ error: "Must be a valid number" })
  .nonnegative("Must be non-negative")
  .finite()
  .transform((v) => v.toString());

// Opening a maintenance record. The vehicle→IN_SHOP side effect lives in the
// service layer, inside a transaction.
export const createMaintenanceSchema = z.object({
  vehicleId: z.string().min(1, "Vehicle is required"),
  description: z.string().trim().min(1, "Description is required").max(500),
  cost: money.optional().default("0"),
});
export type CreateMaintenanceInput = z.infer<typeof createMaintenanceSchema>;

export const maintenanceIdParamSchema = z.object({
  id: z.string().min(1),
});
export type MaintenanceIdParam = z.infer<typeof maintenanceIdParamSchema>;

export const listMaintenanceQuerySchema = z.object({
  vehicleId: z.string().min(1).optional(),
  status: z.enum(MaintenanceStatus).optional(),
  // Whitelisted sortable columns — never pass raw client input into orderBy.
  sortBy: z.enum(["openedAt", "closedAt", "cost", "status"]).optional().default("openedAt"),
  sortDir: z.enum(["asc", "desc"]).optional().default("desc"),
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(20),
});
export type ListMaintenanceQuery = z.infer<typeof listMaintenanceQuerySchema>;
