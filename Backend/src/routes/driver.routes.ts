import { Router } from "express";
import { Role } from "../generated/prisma/client";
import {
  createDriver,
  deleteDriver,
  getDriver,
  listDrivers,
  updateDriver,
} from "../controllers/driver.controller";
import { authenticate } from "../middleware/authenticate";
import { authorize } from "../middleware/authorize";
import { validateBody, validateParams, validateQuery } from "../middleware/validate";
import {
  createDriverSchema,
  driverIdParamSchema,
  listDriversQuerySchema,
  updateDriverSchema,
} from "../schemas/driver.schema";

export const driverRouter = Router();

// Every driver endpoint requires a valid access token.
driverRouter.use(authenticate);

// Read is open to any authenticated role; writes are gated per the RBAC matrix
// in PLAN.md §6 (FLEET_MANAGER + SAFETY_OFFICER own compliance, ADMIN full).
const canWrite = authorize(Role.FLEET_MANAGER, Role.SAFETY_OFFICER, Role.ADMIN);

driverRouter.get("/", validateQuery(listDriversQuerySchema), listDrivers);
driverRouter.get("/:id", validateParams(driverIdParamSchema), getDriver);
driverRouter.post("/", canWrite, validateBody(createDriverSchema), createDriver);
driverRouter.patch(
  "/:id",
  canWrite,
  validateParams(driverIdParamSchema),
  validateBody(updateDriverSchema),
  updateDriver,
);
driverRouter.delete("/:id", canWrite, validateParams(driverIdParamSchema), deleteDriver);
