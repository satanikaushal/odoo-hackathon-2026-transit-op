import { Router } from "express";
import { Role } from "../generated/prisma/client";
import {
  closeMaintenance,
  createMaintenance,
  getMaintenance,
  listMaintenance,
} from "../controllers/maintenance.controller";
import { authenticate } from "../middleware/authenticate";
import { authorize } from "../middleware/authorize";
import { validateBody, validateParams, validateQuery } from "../middleware/validate";
import {
  createMaintenanceSchema,
  listMaintenanceQuerySchema,
  maintenanceIdParamSchema,
} from "../schemas/maintenance.schema";

export const maintenanceRouter = Router();

// Every maintenance endpoint requires a valid access token.
maintenanceRouter.use(authenticate);

// Reads open to any authenticated role; opening/closing records (which move
// vehicle status) is limited to FLEET_MANAGER + ADMIN per PLAN.md §6.
const canManage = authorize(Role.FLEET_MANAGER, Role.ADMIN);

maintenanceRouter.get("/", validateQuery(listMaintenanceQuerySchema), listMaintenance);
maintenanceRouter.get("/:id", validateParams(maintenanceIdParamSchema), getMaintenance);

maintenanceRouter.post("/", canManage, validateBody(createMaintenanceSchema), createMaintenance);

maintenanceRouter.post(
  "/:id/close",
  canManage,
  validateParams(maintenanceIdParamSchema),
  closeMaintenance,
);
