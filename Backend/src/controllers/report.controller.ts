import type { Request, Response } from "express";
import { ok } from "../lib/response";
import { toCsv } from "../lib/csv";
import { tablePdf } from "../lib/pdf";
import { reportService } from "../services/report.service";
import type { ExportQuery, ReportName } from "../schemas/report.schema";

export async function getFuelEfficiency(_req: Request, res: Response) {
  ok(res, await reportService.fuelEfficiency());
}

export async function getFleetUtilization(_req: Request, res: Response) {
  ok(res, await reportService.fleetUtilization());
}

export async function getOperationalCost(_req: Request, res: Response) {
  ok(res, await reportService.operationalCost());
}

export async function getVehicleRoi(_req: Request, res: Response) {
  ok(res, await reportService.vehicleRoi());
}

type ReportTable = { headers: string[]; rows: (string | number | null)[][] };

// Reuses the exact service functions the JSON endpoints call — the CSV and PDF
// paths are just different serializations of the same data (PLAN.md §8.2).
async function buildReportTable(report: ReportName): Promise<ReportTable> {
  switch (report) {
    case "fuel-efficiency": {
      const rows = await reportService.fuelEfficiency();
      return {
        headers: ["vehicleId", "registrationNumber", "name", "totalDistance", "totalLiters", "kmPerLiter"],
        rows: rows.map((r) => [r.vehicleId, r.registrationNumber, r.name, r.totalDistance, r.totalLiters, r.kmPerLiter]),
      };
    }
    case "fleet-utilization": {
      const u = await reportService.fleetUtilization();
      return {
        headers: ["onTripVehicles", "nonRetiredVehicles", "totalVehicles", "utilizationPct"],
        rows: [[u.onTripVehicles, u.nonRetiredVehicles, u.totalVehicles, u.utilizationPct]],
      };
    }
    case "operational-cost": {
      const rows = await reportService.operationalCost();
      return {
        headers: ["vehicleId", "registrationNumber", "name", "fuelCost", "maintenanceCost", "operationalCost"],
        rows: rows.map((r) => [r.vehicleId, r.registrationNumber, r.name, r.fuelCost, r.maintenanceCost, r.operationalCost]),
      };
    }
    case "vehicle-roi": {
      const rows = await reportService.vehicleRoi();
      return {
        headers: ["vehicleId", "registrationNumber", "name", "totalRevenue", "operationalCost", "acquisitionCost", "netProfit", "roi"],
        rows: rows.map((r) => [r.vehicleId, r.registrationNumber, r.name, r.totalRevenue, r.operationalCost, r.acquisitionCost, r.netProfit, r.roi]),
      };
    }
  }
}

export async function exportCsv(req: Request, res: Response) {
  const { report } = req.validated.query as ExportQuery;
  const { headers, rows } = await buildReportTable(report);

  res.setHeader("Content-Type", "text/csv; charset=utf-8");
  res.setHeader("Content-Disposition", `attachment; filename="${report}.csv"`);
  res.send(toCsv(headers, rows));
}

const REPORT_TITLES: Record<ReportName, string> = {
  "fuel-efficiency": "Fuel Efficiency Report",
  "fleet-utilization": "Fleet Utilization Report",
  "operational-cost": "Operational Cost Report",
  "vehicle-roi": "Vehicle ROI Report",
};

export async function exportPdf(req: Request, res: Response) {
  const { report } = req.validated.query as ExportQuery;
  const { headers, rows } = await buildReportTable(report);

  res.setHeader("Content-Type", "application/pdf");
  res.setHeader("Content-Disposition", `attachment; filename="${report}.pdf"`);
  const doc = tablePdf(REPORT_TITLES[report], headers, rows);
  doc.pipe(res);
  doc.end();
}
