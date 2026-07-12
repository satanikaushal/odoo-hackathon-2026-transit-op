-- AlterEnum
BEGIN;
CREATE TYPE "ExpenseCategory_new" AS ENUM ('TOLL', 'MISC');
ALTER TABLE "Expense" ALTER COLUMN "category" TYPE "ExpenseCategory_new" USING ("category"::text::"ExpenseCategory_new");
ALTER TYPE "ExpenseCategory" RENAME TO "ExpenseCategory_old";
ALTER TYPE "ExpenseCategory_new" RENAME TO "ExpenseCategory";
DROP TYPE "public"."ExpenseCategory_old";
COMMIT;

-- AlterTable
ALTER TABLE "Expense" ALTER COLUMN "amount" SET DATA TYPE DECIMAL(12,2);

-- AlterTable
ALTER TABLE "FuelLog" ALTER COLUMN "cost" SET DATA TYPE DECIMAL(12,2);

-- AlterTable
ALTER TABLE "MaintenanceLog" ALTER COLUMN "cost" SET DATA TYPE DECIMAL(12,2);

-- AlterTable
ALTER TABLE "Trip" ALTER COLUMN "revenue" SET DATA TYPE DECIMAL(12,2);

-- AlterTable
ALTER TABLE "Vehicle" ALTER COLUMN "acquisitionCost" SET DATA TYPE DECIMAL(12,2);

-- CreateIndex
CREATE INDEX "Expense_tripId_idx" ON "Expense"("tripId");
