import { Router } from "express";
import { Role } from "../generated/prisma/client";
import {
  cancelTrip,
  completeTrip,
  createTrip,
  dispatchTrip,
  getTrip,
  listTrips,
} from "../controllers/trip.controller";
import { authenticate } from "../middleware/authenticate";
import { authorize } from "../middleware/authorize";
import { validateBody, validateParams, validateQuery } from "../middleware/validate";
import {
  completeTripSchema,
  createTripSchema,
  listTripsQuerySchema,
  tripIdParamSchema,
} from "../schemas/trip.schema";

export const tripRouter = Router();

// Every trip endpoint requires a valid access token.
tripRouter.use(authenticate);

// Reads are open to any authenticated role; the state-machine actions
// (create/dispatch/complete/cancel) are dispatch operations, gated per the RBAC
// matrix in PLAN.md §6 (FLEET_MANAGER + DRIVER dispatcher role + ADMIN).
const canDispatch = authorize(Role.FLEET_MANAGER, Role.DRIVER, Role.ADMIN);

tripRouter.get("/", validateQuery(listTripsQuerySchema), listTrips);
tripRouter.get("/:id", validateParams(tripIdParamSchema), getTrip);

tripRouter.post("/", canDispatch, validateBody(createTripSchema), createTrip);

tripRouter.post(
  "/:id/dispatch",
  canDispatch,
  validateParams(tripIdParamSchema),
  dispatchTrip,
);

tripRouter.post(
  "/:id/complete",
  canDispatch,
  validateParams(tripIdParamSchema),
  validateBody(completeTripSchema),
  completeTrip,
);

tripRouter.post(
  "/:id/cancel",
  canDispatch,
  validateParams(tripIdParamSchema),
  cancelTrip,
);
