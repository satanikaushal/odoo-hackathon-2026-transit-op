import { TripStatus, VehicleStatus } from "../generated/prisma/client";
import { prisma } from "../lib/prisma";
import { costService } from "./cost.service";

// Trips that represent real (or in-progress) vehicle movement. DRAFT trips were
// never dispatched and CANCELLED trips were aborted, so neither contributes to
// distance driven or revenue earned.
const COUNTED_TRIP_STATUSES = [TripStatus.DISPATCHED, TripStatus.COMPLETED];

function round(n: number, digits = 2): number {
  const factor = 10 ** digits;
  return Math.round(n * factor) / factor;
}

export interface FuelEfficiencyRow {
  vehicleId: string;
  registrationNumber: string;
  name: string;
  totalDistance: number;
  totalLiters: number;
  kmPerLiter: number | null; // null when the vehicle has no fuel logs
}

export interface FleetUtilization {
  onTripVehicles: number;
  nonRetiredVehicles: number;
  totalVehicles: number;
  utilizationPct: number | null; // null when the fleet has no non-retired vehicles
}

export interface OperationalCostRow {
  vehicleId: string;
  registrationNumber: string;
  name: string;
  fuelCost: number;
  maintenanceCost: number;
  operationalCost: number;
}

export interface VehicleRoiRow {
  vehicleId: string;
  registrationNumber: string;
  name: string;
  totalRevenue: number;
  operationalCost: number;
  acquisitionCost: number;
  netProfit: number;
  roi: number | null; // null when acquisitionCost is 0 (avoids divide-by-zero)
}

const vehicleIdentity = {
  select: { id: true, registrationNumber: true, name: true },
  orderBy: { registrationNumber: "asc" },
} as const;

export const reportService = {
  // Fuel efficiency per vehicle = distance driven / litres consumed (km/L).
  async fuelEfficiency(): Promise<FuelEfficiencyRow[]> {
    const [vehicles, trips, fuel] = await Promise.all([
      prisma.vehicle.findMany(vehicleIdentity),
      prisma.trip.findMany({
        where: { status: { in: COUNTED_TRIP_STATUSES } },
        select: { vehicleId: true, actualDistance: true, plannedDistance: true },
      }),
      prisma.fuelLog.groupBy({ by: ["vehicleId"], _sum: { liters: true } }),
    ]);

    const distanceByVehicle = new Map<string, number>();
    for (const trip of trips) {
      const distance = trip.actualDistance ?? trip.plannedDistance;
      distanceByVehicle.set(trip.vehicleId, (distanceByVehicle.get(trip.vehicleId) ?? 0) + distance);
    }

    const litersByVehicle = new Map<string, number>();
    for (const row of fuel) litersByVehicle.set(row.vehicleId, row._sum.liters ?? 0);

    return vehicles.map((vehicle) => {
      const totalDistance = distanceByVehicle.get(vehicle.id) ?? 0;
      const totalLiters = litersByVehicle.get(vehicle.id) ?? 0;
      return {
        vehicleId: vehicle.id,
        registrationNumber: vehicle.registrationNumber,
        name: vehicle.name,
        totalDistance: round(totalDistance),
        totalLiters: round(totalLiters),
        kmPerLiter: totalLiters > 0 ? round(totalDistance / totalLiters) : null,
      };
    });
  },

  // Fleet-wide utilization: share of the usable fleet currently on a trip.
  async fleetUtilization(): Promise<FleetUtilization> {
    const [onTripVehicles, nonRetiredVehicles, totalVehicles] = await Promise.all([
      prisma.vehicle.count({ where: { status: VehicleStatus.ON_TRIP } }),
      prisma.vehicle.count({ where: { status: { not: VehicleStatus.RETIRED } } }),
      prisma.vehicle.count(),
    ]);

    return {
      onTripVehicles,
      nonRetiredVehicles,
      totalVehicles,
      utilizationPct: nonRetiredVehicles > 0 ? round((onTripVehicles / nonRetiredVehicles) * 100) : null,
    };
  },

  // Operational cost per vehicle (fuel + maintenance).
  async operationalCost(): Promise<OperationalCostRow[]> {
    const [vehicles, costByVehicle] = await Promise.all([
      prisma.vehicle.findMany(vehicleIdentity),
      costService.operationalCostByVehicle(),
    ]);

    return vehicles.map((vehicle) => {
      const cost = costByVehicle.get(vehicle.id);
      return {
        vehicleId: vehicle.id,
        registrationNumber: vehicle.registrationNumber,
        name: vehicle.name,
        fuelCost: round(cost?.fuelCost ?? 0),
        maintenanceCost: round(cost?.maintenanceCost ?? 0),
        operationalCost: round(cost?.operationalCost ?? 0),
      };
    });
  },

  // Vehicle ROI = (revenue - operational cost) / acquisition cost.
  async vehicleRoi(): Promise<VehicleRoiRow[]> {
    const [vehicles, revenue, costByVehicle] = await Promise.all([
      prisma.vehicle.findMany({
        select: { id: true, registrationNumber: true, name: true, acquisitionCost: true },
        orderBy: { registrationNumber: "asc" },
      }),
      prisma.trip.groupBy({
        by: ["vehicleId"],
        where: { status: { in: COUNTED_TRIP_STATUSES } },
        _sum: { revenue: true },
      }),
      costService.operationalCostByVehicle(),
    ]);

    const revenueByVehicle = new Map<string, number>();
    for (const row of revenue) revenueByVehicle.set(row.vehicleId, row._sum.revenue ?? 0);

    return vehicles.map((vehicle) => {
      const totalRevenue = revenueByVehicle.get(vehicle.id) ?? 0;
      const operationalCost = costByVehicle.get(vehicle.id)?.operationalCost ?? 0;
      const netProfit = totalRevenue - operationalCost;
      return {
        vehicleId: vehicle.id,
        registrationNumber: vehicle.registrationNumber,
        name: vehicle.name,
        totalRevenue: round(totalRevenue),
        operationalCost: round(operationalCost),
        acquisitionCost: round(vehicle.acquisitionCost),
        netProfit: round(netProfit),
        // ROI is a small ratio, so keep more precision than the money fields.
        roi: vehicle.acquisitionCost > 0 ? round(netProfit / vehicle.acquisitionCost, 4) : null,
      };
    });
  },
};
