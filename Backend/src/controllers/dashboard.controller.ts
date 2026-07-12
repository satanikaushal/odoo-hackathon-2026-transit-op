import type { Request, Response } from "express";
import { ok } from "../lib/response";
import { getFilterOptions, getKpis } from "../services/dashboard.service";
import type { DashboardKpisQuery } from "../schemas/dashboard.schema";

export async function kpis(req: Request, res: Response) {
  const filters = req.validated.query as DashboardKpisQuery;
  ok(res, await getKpis(filters));
}

export async function filterOptions(_req: Request, res: Response) {
  ok(res, await getFilterOptions());
}
