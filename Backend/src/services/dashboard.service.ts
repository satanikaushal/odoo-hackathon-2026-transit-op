import { prisma } from "../lib/prisma";
import { VehicleStatus } from "../generated/prisma/enums";

export interface DashboardFilters {
  type?: string;
  status?: VehicleStatus;
  region?: string;
}

export interface DashboardKpis {
  activeVehicles: number;
  availableVehicles: number;
  vehiclesInMaintenance: number;
  activeTrips: number;
  pendingTrips: number;
  driversOnDuty: number;
  fleetUtilization: number;
}

// Trip counts are narrowed through the trip's vehicle; driver counts are
// global — drivers have no type/region to filter on.
export async function getKpis(filters: DashboardFilters): Promise<DashboardKpis> {
  const vehicleWhere = {
    ...(filters.type && { type: filters.type }),
    ...(filters.status && { status: filters.status }),
    ...(filters.region && { region: filters.region }),
  };

  const [vehicleGroups, tripGroups, driversOnDuty] = await Promise.all([
    prisma.vehicle.groupBy({ by: ["status"], where: vehicleWhere, _count: { _all: true } }),
    prisma.trip.groupBy({
      by: ["status"],
      where: { status: { in: ["DRAFT", "DISPATCHED"] }, vehicle: vehicleWhere },
      _count: { _all: true },
    }),
    prisma.driver.count({ where: { status: { in: ["AVAILABLE", "ON_TRIP"] } } }),
  ]);

  const vehicles = (status: VehicleStatus) =>
    vehicleGroups.find((g) => g.status === status)?._count._all ?? 0;
  const trips = (status: "DRAFT" | "DISPATCHED") =>
    tripGroups.find((g) => g.status === status)?._count._all ?? 0;

  const activeVehicles = vehicles("ON_TRIP");
  const nonRetired = vehicleGroups.reduce(
    (sum, g) => (g.status === "RETIRED" ? sum : sum + g._count._all),
    0,
  );

  return {
    activeVehicles,
    availableVehicles: vehicles("AVAILABLE"),
    vehiclesInMaintenance: vehicles("IN_SHOP"),
    activeTrips: trips("DISPATCHED"),
    pendingTrips: trips("DRAFT"),
    driversOnDuty,
    fleetUtilization: nonRetired === 0 ? 0 : Math.round((activeVehicles / nonRetired) * 10000) / 100,
  };
}

export interface DashboardFilterOptions {
  types: string[];
  regions: string[];
  statuses: VehicleStatus[];
}

export async function getFilterOptions(): Promise<DashboardFilterOptions> {
  const [types, regions] = await Promise.all([
    prisma.vehicle.findMany({
      distinct: ["type"],
      select: { type: true },
      orderBy: { type: "asc" },
    }),
    prisma.vehicle.findMany({
      distinct: ["region"],
      select: { region: true },
      where: { region: { not: null } },
      orderBy: { region: "asc" },
    }),
  ]);

  return {
    types: types.map((v) => v.type),
    regions: regions.map((v) => v.region as string),
    statuses: Object.values(VehicleStatus),
  };
}
