import { z } from "zod";
import { VehicleStatus } from "../generated/prisma/enums";

const vehicleStatus = z.enum(VehicleStatus);

// Money is validated as a numeric value but carried as a string so the Decimal
// column keeps full precision (JS numbers would round large acquisition costs).
const money = z.coerce
  .number({ error: "Must be a valid number" })
  .nonnegative("Must be non-negative")
  .finite()
  .transform((v) => v.toString());

const registrationNumber = z
  .string()
  .trim()
  .min(1, "Registration number is required")
  .max(32)
  .transform((v) => v.toUpperCase());

export const createVehicleSchema = z.object({
  registrationNumber,
  name: z.string().trim().min(1, "Name is required").max(120),
  type: z.string().trim().min(1, "Type is required").max(60),
  maxLoadCapacity: z.coerce.number().positive("Max load capacity must be positive").finite(),
  odometer: z.coerce.number().nonnegative().finite().optional().default(0),
  acquisitionCost: money,
  status: vehicleStatus.optional().default(VehicleStatus.AVAILABLE),
  region: z.string().trim().min(1).max(80).optional(),
});
export type CreateVehicleInput = z.infer<typeof createVehicleSchema>;

export const updateVehicleSchema = z
  .object({
    registrationNumber,
    name: z.string().trim().min(1).max(120),
    type: z.string().trim().min(1).max(60),
    maxLoadCapacity: z.coerce.number().positive().finite(),
    odometer: z.coerce.number().nonnegative().finite(),
    acquisitionCost: money,
    status: vehicleStatus,
    region: z.string().trim().min(1).max(80).nullable(),
  })
  .partial()
  .refine((data) => Object.keys(data).length > 0, {
    message: "At least one field must be provided",
  });
export type UpdateVehicleInput = z.infer<typeof updateVehicleSchema>;

export const updateVehicleStatusSchema = z.object({
  status: vehicleStatus,
});
export type UpdateVehicleStatusInput = z.infer<typeof updateVehicleStatusSchema>;

export const vehicleIdParamsSchema = z.object({
  id: z.string().min(1),
});

export const listVehiclesQuerySchema = z.object({
  status: vehicleStatus.optional(),
  type: z.string().trim().min(1).optional(),
  region: z.string().trim().min(1).optional(),
  // Free-text match against registration number or name.
  search: z.string().trim().min(1).optional(),
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(20),
});
export type ListVehiclesQuery = z.infer<typeof listVehiclesQuerySchema>;
