import { z } from "zod";
import { VehicleStatus } from "../generated/prisma/enums";

export const dashboardKpisQuerySchema = z.object({
  type: z.string().min(1).optional(),
  status: z.enum(VehicleStatus).optional(),
  region: z.string().min(1).optional(),
});

export type DashboardKpisQuery = z.infer<typeof dashboardKpisQuerySchema>;
