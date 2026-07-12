import { Router } from "express";
import { filterOptions, kpis } from "../controllers/dashboard.controller";
import { authenticate } from "../middleware/authenticate";
import { validateQuery } from "../middleware/validate";
import { dashboardKpisQuerySchema } from "../schemas/dashboard.schema";

// Every role sees the dashboard (RBAC matrix: full for all) — authenticate only.
export const dashboardRouter = Router();

dashboardRouter.get("/kpis", authenticate, validateQuery(dashboardKpisQuerySchema), kpis);
dashboardRouter.get("/filters", authenticate, filterOptions);
