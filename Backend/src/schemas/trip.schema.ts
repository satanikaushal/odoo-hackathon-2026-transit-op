import { z } from "zod";
import { TripStatus } from "../generated/prisma/client";

// Money is validated as a numeric value but carried as a string so the Decimal
// column keeps full precision (mirrors vehicle.schema's `money`).
const money = z.coerce
  .number({ error: "Must be a valid number" })
  .nonnegative("Must be non-negative")
  .finite()
  .transform((v) => v.toString());

// Shape validation only. The cross-entity rules — vehicle/driver availability,
// license expiry, cargo-vs-capacity — need DB reads and live in the service
// layer per PLAN.md §4. `status` is server-owned (always DRAFT on create), so
// it is intentionally NOT accepted from the client here.
export const createTripSchema = z.object({
  source: z.string().trim().min(1, "Source is required").max(120),
  destination: z.string().trim().min(1, "Destination is required").max(120),
  vehicleId: z.string().min(1, "Vehicle is required"),
  driverId: z.string().min(1, "Driver is required"),
  cargoWeight: z.coerce.number().positive("Cargo weight must be positive").finite(),
  plannedDistance: z.coerce.number().positive("Planned distance must be positive").finite(),
});
export type CreateTripInput = z.infer<typeof createTripSchema>;

// Completion captures the real-world outcome. `finalOdometer` is required (it is
// written back onto the vehicle); the service rejects a value below the
// vehicle's current reading. `actualDistance` is derived, not client-supplied.
export const completeTripSchema = z.object({
  finalOdometer: z.coerce.number().nonnegative().finite(),
  fuelConsumed: z.coerce.number().nonnegative().finite().optional(),
  revenue: money.optional(),
});
export type CompleteTripInput = z.infer<typeof completeTripSchema>;

export const tripIdParamSchema = z.object({
  id: z.string().min(1),
});
export type TripIdParam = z.infer<typeof tripIdParamSchema>;

export const listTripsQuerySchema = z.object({
  status: z.enum(TripStatus).optional(),
  vehicleId: z.string().min(1).optional(),
  driverId: z.string().min(1).optional(),
  search: z.string().trim().min(1).optional(),
  // Whitelisted sortable columns — never pass raw client input into orderBy.
  sortBy: z
    .enum(["createdAt", "dispatchedAt", "completedAt", "source", "destination", "status", "cargoWeight"])
    .optional()
    .default("createdAt"),
  sortDir: z.enum(["asc", "desc"]).optional().default("desc"),
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(20),
});
export type ListTripsQuery = z.infer<typeof listTripsQuerySchema>;
