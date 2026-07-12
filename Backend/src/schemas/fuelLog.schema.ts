import { z } from "zod";

// Money is validated numerically but carried as a string for Decimal precision
// (mirrors vehicle.schema / maintenance.schema `money`).
const money = z.coerce
  .number({ error: "Must be a valid number" })
  .nonnegative("Must be non-negative")
  .finite()
  .transform((v) => v.toString());

// Record a fuel purchase for a vehicle. Optionally attributed to a specific trip.
export const createFuelLogSchema = z.object({
  vehicleId: z.string().min(1, "Vehicle is required"),
  tripId: z.string().min(1).optional(),
  liters: z.coerce.number().positive("Liters must be positive").finite(),
  cost: money,
  // Defaults to now() at the DB layer when omitted.
  date: z.coerce.date().optional(),
});
export type CreateFuelLogInput = z.infer<typeof createFuelLogSchema>;

export const fuelLogIdParamSchema = z.object({
  id: z.string().min(1),
});
export type FuelLogIdParam = z.infer<typeof fuelLogIdParamSchema>;

export const listFuelLogsQuerySchema = z.object({
  vehicleId: z.string().min(1).optional(),
  tripId: z.string().min(1).optional(),
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(20),
});
export type ListFuelLogsQuery = z.infer<typeof listFuelLogsQuerySchema>;
