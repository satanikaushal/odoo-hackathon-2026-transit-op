import { prisma } from "../lib/prisma";

export interface VehicleCost {
  fuelCost: number;
  maintenanceCost: number;
  operationalCost: number;
}

function blankCost(): VehicleCost {
  return { fuelCost: 0, maintenanceCost: 0, operationalCost: 0 };
}

// Operational cost = fuel spend + maintenance spend (PLAN.md §6.3). Expenses
// (tolls / misc) are tracked separately and are deliberately NOT part of this
// figure, keeping it consistent with the ROI formula in §8.
export const costService = {
  // Single vehicle — used by per-resource responses.
  async totalOperationalCost(vehicleId: string): Promise<VehicleCost> {
    const [fuel, maintenance] = await Promise.all([
      prisma.fuelLog.aggregate({ where: { vehicleId }, _sum: { cost: true } }),
      prisma.maintenanceLog.aggregate({ where: { vehicleId }, _sum: { cost: true } }),
    ]);
    // _sum on a Decimal column returns a Decimal object — convert at the boundary.
    const fuelCost = Number(fuel._sum.cost ?? 0);
    const maintenanceCost = Number(maintenance._sum.cost ?? 0);
    return { fuelCost, maintenanceCost, operationalCost: fuelCost + maintenanceCost };
  },

  // Whole fleet at once — one groupBy per table instead of N per-vehicle round
  // trips. Vehicles with no fuel/maintenance rows are simply absent from the
  // map (callers default them to zero).
  async operationalCostByVehicle(): Promise<Map<string, VehicleCost>> {
    const [fuel, maintenance] = await Promise.all([
      prisma.fuelLog.groupBy({ by: ["vehicleId"], _sum: { cost: true } }),
      prisma.maintenanceLog.groupBy({ by: ["vehicleId"], _sum: { cost: true } }),
    ]);

    const byVehicle = new Map<string, VehicleCost>();
    for (const row of fuel) {
      const cost = byVehicle.get(row.vehicleId) ?? blankCost();
      cost.fuelCost = Number(row._sum.cost ?? 0);
      byVehicle.set(row.vehicleId, cost);
    }
    for (const row of maintenance) {
      const cost = byVehicle.get(row.vehicleId) ?? blankCost();
      cost.maintenanceCost = Number(row._sum.cost ?? 0);
      byVehicle.set(row.vehicleId, cost);
    }
    for (const cost of byVehicle.values()) {
      cost.operationalCost = cost.fuelCost + cost.maintenanceCost;
    }
    return byVehicle;
  },
};
