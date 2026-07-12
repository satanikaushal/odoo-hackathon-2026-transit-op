import type { Request, Response } from "express";
import { created, ok } from "../lib/response";
import { reqLogger } from "../lib/logger";
import { fuelLogService } from "../services/fuelLog.service";
import type {
  CreateFuelLogInput,
  FuelLogIdParam,
  ListFuelLogsQuery,
} from "../schemas/fuelLog.schema";

export async function listFuelLogs(req: Request, res: Response) {
  const query = req.validated.query as ListFuelLogsQuery;
  const result = await fuelLogService.list(query);
  reqLogger(req).debug(
    { filters: query, returned: result.items.length, total: result.pagination.total },
    "listed fuel logs",
  );
  ok(res, result);
}

export async function getFuelLog(req: Request, res: Response) {
  const { id } = req.validated.params as FuelLogIdParam;
  const log = await fuelLogService.getById(id);
  reqLogger(req).debug({ fuelLogId: id }, "fetched fuel log");
  ok(res, log);
}

export async function createFuelLog(req: Request, res: Response) {
  const input = req.validated.body as CreateFuelLogInput;
  const log = await fuelLogService.create(input);
  reqLogger(req).info(
    { fuelLogId: log.id, vehicleId: log.vehicleId, tripId: log.tripId },
    "fuel log recorded",
  );
  created(res, log, "Fuel log recorded");
}
