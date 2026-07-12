import { Router } from "express";
import { Role } from "../generated/prisma/client";
import { createExpense, getExpense, listExpenses } from "../controllers/expense.controller";
import { authenticate } from "../middleware/authenticate";
import { authorize } from "../middleware/authorize";
import { validateBody, validateParams, validateQuery } from "../middleware/validate";
import {
  createExpenseSchema,
  expenseIdParamSchema,
  listExpensesQuerySchema,
} from "../schemas/expense.schema";

export const expenseRouter = Router();

expenseRouter.use(authenticate);

// Per PLAN.md §6: fleet managers + admins record/manage expenses; financial
// analysts read them for cost analysis.
const canRead = authorize(Role.FLEET_MANAGER, Role.ADMIN, Role.FINANCIAL_ANALYST);
const canManage = authorize(Role.FLEET_MANAGER, Role.ADMIN);

expenseRouter.get("/", canRead, validateQuery(listExpensesQuerySchema), listExpenses);
expenseRouter.get("/:id", canRead, validateParams(expenseIdParamSchema), getExpense);

expenseRouter.post("/", canManage, validateBody(createExpenseSchema), createExpense);
