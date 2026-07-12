import type { Request, Response } from "express";
import { ok } from "../lib/response";
import { reqLogger } from "../lib/logger";
import { getFilterOptions, getKpis } from "../services/dashboard.service";
import type { DashboardKpisQuery } from "../schemas/dashboard.schema";

export async function kpis(req: Request, res: Response) {
  const filters = req.validated.query as DashboardKpisQuery;
  reqLogger(req).debug({ filters }, "computed dashboard KPIs");
  ok(res, await getKpis(filters));
}

export async function filterOptions(req: Request, res: Response) {
  reqLogger(req).debug("fetched dashboard filter options");
  ok(res, await getFilterOptions());
}
