import type { Request, Response } from "express";
import { created, ok } from "../lib/response";
import { reqLogger } from "../lib/logger";
import { expenseService } from "../services/expense.service";
import type {
  CreateExpenseInput,
  ExpenseIdParam,
  ListExpensesQuery,
} from "../schemas/expense.schema";

export async function listExpenses(req: Request, res: Response) {
  const query = req.validated.query as ListExpensesQuery;
  const result = await expenseService.list(query);
  reqLogger(req).debug(
    { filters: query, returned: result.items.length, total: result.pagination.total },
    "listed expenses",
  );
  ok(res, result);
}

export async function getExpense(req: Request, res: Response) {
  const { id } = req.validated.params as ExpenseIdParam;
  const expense = await expenseService.getById(id);
  reqLogger(req).debug({ expenseId: id }, "fetched expense");
  ok(res, expense);
}

export async function createExpense(req: Request, res: Response) {
  const input = req.validated.body as CreateExpenseInput;
  const expense = await expenseService.create(input);
  reqLogger(req).info(
    { expenseId: expense.id, vehicleId: expense.vehicleId, category: expense.category },
    "expense recorded",
  );
  created(res, expense, "Expense recorded");
}
