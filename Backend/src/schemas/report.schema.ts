import { z } from "zod";

// Report identifiers, shared by the CSV export endpoint. The JSON endpoints
// each have their own route, but export.csv selects one via ?report=.
export const REPORT_NAMES = [
  "fuel-efficiency",
  "fleet-utilization",
  "operational-cost",
  "vehicle-roi",
] as const;
export type ReportName = (typeof REPORT_NAMES)[number];

export const exportQuerySchema = z.object({
  report: z.enum(REPORT_NAMES),
});
export type ExportQuery = z.infer<typeof exportQuerySchema>;
