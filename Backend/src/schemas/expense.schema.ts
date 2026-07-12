import { z } from "zod";
import { ExpenseCategory } from "../generated/prisma/client";

// Money is validated numerically but carried as a string for Decimal precision.
const money = z.coerce
  .number({ error: "Must be a valid number" })
  .positive("Amount must be positive")
  .finite()
  .transform((v) => v.toString());

// Record a non-fuel operational expense (toll / misc). Maintenance is NOT a
// category here — its costs live on MaintenanceLog to avoid double-counting in
// the operational-cost formula (see schema.prisma ExpenseCategory comment).
export const createExpenseSchema = z.object({
  vehicleId: z.string().min(1, "Vehicle is required"),
  tripId: z.string().min(1).optional(),
  category: z.enum(ExpenseCategory),
  amount: money,
  description: z.string().trim().max(500).optional(),
  // Defaults to now() at the DB layer when omitted.
  date: z.coerce.date().optional(),
});
export type CreateExpenseInput = z.infer<typeof createExpenseSchema>;

export const expenseIdParamSchema = z.object({
  id: z.string().min(1),
});
export type ExpenseIdParam = z.infer<typeof expenseIdParamSchema>;

export const listExpensesQuerySchema = z.object({
  vehicleId: z.string().min(1).optional(),
  tripId: z.string().min(1).optional(),
  category: z.enum(ExpenseCategory).optional(),
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(20),
});
export type ListExpensesQuery = z.infer<typeof listExpensesQuerySchema>;
