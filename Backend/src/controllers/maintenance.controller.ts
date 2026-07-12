import type { Request, Response } from "express";
import { created, ok } from "../lib/response";
import { reqLogger } from "../lib/logger";
import { maintenanceService } from "../services/maintenance.service";
import type {
  CreateMaintenanceInput,
  ListMaintenanceQuery,
  MaintenanceIdParam,
} from "../schemas/maintenance.schema";

export async function listMaintenance(req: Request, res: Response) {
  const query = req.validated.query as ListMaintenanceQuery;
  const result = await maintenanceService.list(query);
  reqLogger(req).debug(
    { filters: query, returned: result.items.length, total: result.pagination.total },
    "listed maintenance records",
  );
  ok(res, result);
}

export async function getMaintenance(req: Request, res: Response) {
  const { id } = req.validated.params as MaintenanceIdParam;
  const log = await maintenanceService.getById(id);
  reqLogger(req).debug({ maintenanceId: id }, "fetched maintenance record");
  ok(res, log);
}

export async function createMaintenance(req: Request, res: Response) {
  const input = req.validated.body as CreateMaintenanceInput;
  const log = await maintenanceService.create(input);
  reqLogger(req).info(
    { maintenanceId: log.id, vehicleId: log.vehicleId, status: log.status },
    "maintenance opened; vehicle set IN_SHOP",
  );
  created(res, log, "Maintenance record opened");
}

export async function closeMaintenance(req: Request, res: Response) {
  const { id } = req.validated.params as MaintenanceIdParam;
  const log = await maintenanceService.close(id);
  reqLogger(req).info(
    { maintenanceId: log.id, vehicleId: log.vehicleId, status: log.status },
    "maintenance closed; vehicle restored unless retired or still under other maintenance",
  );
  ok(res, log, 200, "Maintenance record closed");
}
