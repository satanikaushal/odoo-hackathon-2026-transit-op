import { Router } from "express";
import {
  createVehicle,
  deleteVehicle,
  getVehicle,
  getVehicleCosts,
  listVehicles,
  listVehiclesAvailableForDispatch,
  updateVehicle,
  updateVehicleStatus,
} from "../controllers/vehicle.controller";
import { authenticate } from "../middleware/authenticate";
import { authorize } from "../middleware/authorize";
import { validateBody, validateParams, validateQuery } from "../middleware/validate";
import { Role } from "../generated/prisma/enums";
import {
  createVehicleSchema,
  listVehiclesQuerySchema,
  updateVehicleSchema,
  updateVehicleStatusSchema,
  vehicleIdParamsSchema,
} from "../schemas/vehicle.schema";

export const vehicleRouter = Router();

// The registry is master data: any authenticated user may read it, but only
// admins and fleet managers may create, modify, or delete vehicles.
const canManage = authorize(Role.ADMIN, Role.FLEET_MANAGER);

vehicleRouter.use(authenticate);

vehicleRouter.get("/", validateQuery(listVehiclesQuerySchema), listVehicles);
// Must precede "/:id" so it isn't captured as a vehicle id.
vehicleRouter.get("/available-for-dispatch", listVehiclesAvailableForDispatch);
vehicleRouter.get("/:id", validateParams(vehicleIdParamsSchema), getVehicle);
vehicleRouter.get("/:id/costs", validateParams(vehicleIdParamsSchema), getVehicleCosts);

vehicleRouter.post("/", canManage, validateBody(createVehicleSchema), createVehicle);

vehicleRouter.patch(
  "/:id",
  canManage,
  validateParams(vehicleIdParamsSchema),
  validateBody(updateVehicleSchema),
  updateVehicle,
);

vehicleRouter.patch(
  "/:id/status",
  canManage,
  validateParams(vehicleIdParamsSchema),
  validateBody(updateVehicleStatusSchema),
  updateVehicleStatus,
);

vehicleRouter.delete("/:id", canManage, validateParams(vehicleIdParamsSchema), deleteVehicle);
