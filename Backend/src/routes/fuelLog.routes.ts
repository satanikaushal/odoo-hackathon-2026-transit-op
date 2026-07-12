import { Router } from "express";
import { Role } from "../generated/prisma/client";
import { createFuelLog, getFuelLog, listFuelLogs } from "../controllers/fuelLog.controller";
import { authenticate } from "../middleware/authenticate";
import { authorize } from "../middleware/authorize";
import { validateBody, validateParams, validateQuery } from "../middleware/validate";
import {
  createFuelLogSchema,
  fuelLogIdParamSchema,
  listFuelLogsQuerySchema,
} from "../schemas/fuelLog.schema";

export const fuelLogRouter = Router();

fuelLogRouter.use(authenticate);

// Per PLAN.md §6: fleet managers + admins have full access; DRIVER (dispatcher)
// may log fuel; financial analysts read for cost analysis.
const canRead = authorize(Role.FLEET_MANAGER, Role.ADMIN, Role.FINANCIAL_ANALYST, Role.DRIVER);
const canLog = authorize(Role.FLEET_MANAGER, Role.ADMIN, Role.DRIVER);

fuelLogRouter.get("/", canRead, validateQuery(listFuelLogsQuerySchema), listFuelLogs);
fuelLogRouter.get("/:id", canRead, validateParams(fuelLogIdParamSchema), getFuelLog);

fuelLogRouter.post("/", canLog, validateBody(createFuelLogSchema), createFuelLog);
