import type { Request, Response } from "express";
import { created, ok } from "../lib/response";
import { reqLogger } from "../lib/logger";
import { driverService } from "../services/driver.service";
import type {
  CreateDriverInput,
  DriverIdParam,
  ListDriversQuery,
  UpdateDriverInput,
} from "../schemas/driver.schema";

export async function listDrivers(req: Request, res: Response) {
  const query = req.validated.query as ListDriversQuery;
  const drivers = await driverService.list(query);
  reqLogger(req).debug({ filters: query, returned: drivers.length }, "listed drivers");
  ok(res, drivers);
}

export async function getDriver(req: Request, res: Response) {
  const { id } = req.validated.params as DriverIdParam;
  const driver = await driverService.getById(id);
  reqLogger(req).debug({ driverId: id }, "fetched driver");
  ok(res, driver);
}

export async function createDriver(req: Request, res: Response) {
  const input = req.validated.body as CreateDriverInput;
  const driver = await driverService.create(input);
  reqLogger(req).info(
    { driverId: driver.id, licenseNumber: driver.licenseNumber, status: driver.status },
    "driver created",
  );
  created(res, driver);
}

export async function updateDriver(req: Request, res: Response) {
  const { id } = req.validated.params as DriverIdParam;
  const input = req.validated.body as UpdateDriverInput;
  const driver = await driverService.update(id, input);
  reqLogger(req).info({ driverId: id, fields: Object.keys(input) }, "driver updated");
  ok(res, driver);
}

export async function deleteDriver(req: Request, res: Response) {
  const { id } = req.validated.params as DriverIdParam;
  await driverService.remove(id);
  reqLogger(req).info({ driverId: id }, "driver deleted");
  res.status(204).send();
}
