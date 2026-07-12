import type { Request, Response } from "express";
import { created, ok } from "../lib/response";
import { reqLogger } from "../lib/logger";
import { vehicleService } from "../services/vehicle.service";
import { costService } from "../services/cost.service";
import type {
  CreateVehicleInput,
  ListVehiclesQuery,
  UpdateVehicleInput,
  UpdateVehicleStatusInput,
} from "../schemas/vehicle.schema";

export async function createVehicle(req: Request, res: Response) {
  const input = req.validated.body as CreateVehicleInput;
  const vehicle = await vehicleService.create(input);
  reqLogger(req).info(
    { vehicleId: vehicle.id, registrationNumber: vehicle.registrationNumber },
    "vehicle created",
  );
  created(res, vehicle, "Vehicle created");
}

export async function listVehicles(req: Request, res: Response) {
  const query = req.validated.query as ListVehiclesQuery;
  const result = await vehicleService.list(query);
  reqLogger(req).debug(
    { filters: query, returned: result.items.length, total: result.pagination.total },
    "listed vehicles",
  );
  ok(res, result);
}

// The pool of AVAILABLE vehicles for the dispatch/trip-creation picker (§5).
export async function listVehiclesAvailableForDispatch(req: Request, res: Response) {
  const vehicles = await vehicleService.listAvailableForDispatch();
  reqLogger(req).debug({ returned: vehicles.length }, "listed vehicles available for dispatch");
  ok(res, vehicles);
}

export async function getVehicle(req: Request, res: Response) {
  const { id } = req.validated.params as { id: string };
  const vehicle = await vehicleService.getById(id);
  reqLogger(req).debug({ vehicleId: id }, "fetched vehicle");
  ok(res, vehicle);
}

// Total operational cost (fuel + maintenance) for a single vehicle, per §3.7.
export async function getVehicleCosts(req: Request, res: Response) {
  const { id } = req.validated.params as { id: string };
  // 404 cleanly if the vehicle doesn't exist rather than returning zero costs.
  await vehicleService.getById(id);
  const costs = await costService.totalOperationalCost(id);
  reqLogger(req).debug({ vehicleId: id, ...costs }, "computed vehicle operational cost");
  ok(res, { vehicleId: id, ...costs });
}

export async function updateVehicle(req: Request, res: Response) {
  const { id } = req.validated.params as { id: string };
  const input = req.validated.body as UpdateVehicleInput;
  const vehicle = await vehicleService.update(id, input);
  reqLogger(req).info({ vehicleId: id, fields: Object.keys(input) }, "vehicle updated");
  ok(res, vehicle, 200, "Vehicle updated");
}

export async function updateVehicleStatus(req: Request, res: Response) {
  const { id } = req.validated.params as { id: string };
  const { status } = req.validated.body as UpdateVehicleStatusInput;
  const vehicle = await vehicleService.updateStatus(id, status);
  reqLogger(req).info({ vehicleId: id, status }, "vehicle status changed");
  ok(res, vehicle, 200, "Vehicle status updated");
}

export async function deleteVehicle(req: Request, res: Response) {
  const { id } = req.validated.params as { id: string };
  await vehicleService.remove(id);
  reqLogger(req).info({ vehicleId: id }, "vehicle deleted");
  res.status(204).send();
}
