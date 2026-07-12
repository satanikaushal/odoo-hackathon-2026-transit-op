import type { Prisma } from "../generated/prisma/client";
import { prisma } from "../lib/prisma";
import { ApiError } from "../lib/ApiError";
import type { CreateFuelLogInput, ListFuelLogsQuery } from "../schemas/fuelLog.schema";

const vehicleIdentity = {
  select: { id: true, registrationNumber: true, name: true, status: true },
} as const;

// If a fuel log is attributed to a trip, that trip must belong to the same
// vehicle — otherwise per-vehicle cost/efficiency figures would be skewed.
async function assertVehicleAndTrip(vehicleId: string, tripId?: string) {
  const vehicle = await prisma.vehicle.findUnique({ where: { id: vehicleId } });
  if (!vehicle) throw ApiError.notFound("Vehicle not found");

  if (tripId) {
    const trip = await prisma.trip.findUnique({ where: { id: tripId } });
    if (!trip) throw ApiError.notFound("Trip not found");
    if (trip.vehicleId !== vehicleId) {
      throw ApiError.badRequest("Trip does not belong to the specified vehicle");
    }
  }
}

export const fuelLogService = {
  async create(input: CreateFuelLogInput) {
    await assertVehicleAndTrip(input.vehicleId, input.tripId);

    return prisma.fuelLog.create({
      data: {
        vehicleId: input.vehicleId,
        tripId: input.tripId,
        liters: input.liters,
        cost: input.cost,
        ...(input.date && { date: input.date }),
      },
    });
  },

  async list({ vehicleId, tripId, page, limit }: ListFuelLogsQuery) {
    const where: Prisma.FuelLogWhereInput = {
      ...(vehicleId && { vehicleId }),
      ...(tripId && { tripId }),
    };

    const [items, total] = await Promise.all([
      prisma.fuelLog.findMany({
        where,
        orderBy: { date: "desc" },
        skip: (page - 1) * limit,
        take: limit,
        include: { vehicle: vehicleIdentity },
      }),
      prisma.fuelLog.count({ where }),
    ]);

    return {
      items,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  },

  async getById(id: string) {
    const log = await prisma.fuelLog.findUnique({
      where: { id },
      include: { vehicle: vehicleIdentity },
    });
    if (!log) throw ApiError.notFound("Fuel log not found");
    return log;
  },
};
