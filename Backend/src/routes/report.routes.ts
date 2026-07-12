import { Router } from "express";
import { Role } from "../generated/prisma/client";
import {
  exportCsv,
  getFleetUtilization,
  getFuelEfficiency,
  getOperationalCost,
  getVehicleRoi,
} from "../controllers/report.controller";
import { authenticate } from "../middleware/authenticate";
import { authorize } from "../middleware/authorize";
import { validateQuery } from "../middleware/validate";
import { exportQuerySchema } from "../schemas/report.schema";

export const reportRouter = Router();

// Reports are read-only. Per the RBAC matrix (PLAN.md §6) every role except
// DRIVER (dispatcher) may read them, so a single gate covers all endpoints.
reportRouter.use(authenticate);
reportRouter.use(authorize(Role.FLEET_MANAGER, Role.FINANCIAL_ANALYST, Role.SAFETY_OFFICER, Role.ADMIN));

reportRouter.get("/fuel-efficiency", getFuelEfficiency);
reportRouter.get("/fleet-utilization", getFleetUtilization);
reportRouter.get("/operational-cost", getOperationalCost);
reportRouter.get("/vehicle-roi", getVehicleRoi);
reportRouter.get("/export.csv", validateQuery(exportQuerySchema), exportCsv);
