import type { Request, Response } from "express";
import { created, ok } from "../lib/response";
import { vehicleService } from "../services/vehicle.service";
import type {
  CreateVehicleInput,
  ListVehiclesQuery,
  UpdateVehicleInput,
  UpdateVehicleStatusInput,
} from "../schemas/vehicle.schema";

export async function createVehicle(req: Request, res: Response) {
  const input = req.validated.body as CreateVehicleInput;
  const vehicle = await vehicleService.create(input);
  created(res, vehicle, "Vehicle created");
}

export async function listVehicles(req: Request, res: Response) {
  const query = req.validated.query as ListVehiclesQuery;
  const result = await vehicleService.list(query);
  ok(res, result);
}

export async function getVehicle(req: Request, res: Response) {
  const { id } = req.validated.params as { id: string };
  const vehicle = await vehicleService.getById(id);
  ok(res, vehicle);
}

export async function updateVehicle(req: Request, res: Response) {
  const { id } = req.validated.params as { id: string };
  const input = req.validated.body as UpdateVehicleInput;
  const vehicle = await vehicleService.update(id, input);
  ok(res, vehicle, 200, "Vehicle updated");
}

export async function updateVehicleStatus(req: Request, res: Response) {
  const { id } = req.validated.params as { id: string };
  const { status } = req.validated.body as UpdateVehicleStatusInput;
  const vehicle = await vehicleService.updateStatus(id, status);
  ok(res, vehicle, 200, "Vehicle status updated");
}

export async function deleteVehicle(req: Request, res: Response) {
  const { id } = req.validated.params as { id: string };
  await vehicleService.remove(id);
  res.status(204).send();
}
