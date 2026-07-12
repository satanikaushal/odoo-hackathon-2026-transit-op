import { Prisma, MaintenanceStatus, VehicleStatus } from "../generated/prisma/client";
import { prisma } from "../lib/prisma";
import { ApiError } from "../lib/ApiError";
import type {
  CreateMaintenanceInput,
  ListMaintenanceQuery,
} from "../schemas/maintenance.schema";

type Tx = Prisma.TransactionClient;

export const maintenanceService = {
  async list({ vehicleId, status, page, limit }: ListMaintenanceQuery) {
    const where: Prisma.MaintenanceLogWhereInput = {
      ...(vehicleId && { vehicleId }),
      ...(status && { status }),
    };

    const [items, total] = await Promise.all([
      prisma.maintenanceLog.findMany({
        where,
        orderBy: { openedAt: "desc" },
        skip: (page - 1) * limit,
        take: limit,
        include: {
          vehicle: { select: { id: true, registrationNumber: true, name: true, status: true } },
        },
      }),
      prisma.maintenanceLog.count({ where }),
    ]);

    return {
      items,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  },

  async getById(id: string) {
    const log = await prisma.maintenanceLog.findUnique({
      where: { id },
      include: { vehicle: true },
    });
    if (!log) throw ApiError.notFound("Maintenance record not found");
    return log;
  },

  // Open a maintenance record and move the vehicle to IN_SHOP atomically. A
  // vehicle that is on a trip must be completed/cancelled first; a retired
  // vehicle has no operational maintenance workflow.
  async create(input: CreateMaintenanceInput) {
    return prisma.$transaction(async (tx: Tx) => {
      const vehicle = await tx.vehicle.findUnique({ where: { id: input.vehicleId } });
      if (!vehicle) throw ApiError.notFound("Vehicle not found");

      if (vehicle.status === VehicleStatus.ON_TRIP) {
        throw ApiError.conflict(
          "Vehicle is on a trip; complete or cancel the trip before opening maintenance",
        );
      }
      if (vehicle.status === VehicleStatus.RETIRED) {
        throw ApiError.conflict("Vehicle is retired and cannot enter maintenance");
      }

      const log = await tx.maintenanceLog.create({
        data: {
          vehicleId: input.vehicleId,
          description: input.description,
          cost: input.cost,
          status: MaintenanceStatus.OPEN,
        },
      });

      // Idempotent w.r.t. an already-IN_SHOP vehicle (a second open record just
      // keeps it in the shop), but always assert the invariant.
      await tx.vehicle.update({
        where: { id: input.vehicleId },
        data: { status: VehicleStatus.IN_SHOP },
      });

      return log;
    });
  },

  // Close a maintenance record and restore the vehicle to AVAILABLE — unless it
  // was independently retired, or it still has other open maintenance records.
  async close(id: string) {
    return prisma.$transaction(async (tx: Tx) => {
      const log = await tx.maintenanceLog.findUnique({ where: { id } });
      if (!log) throw ApiError.notFound("Maintenance record not found");
      if (log.status === MaintenanceStatus.CLOSED) {
        throw ApiError.conflict("Maintenance record is already closed");
      }

      const closed = await tx.maintenanceLog.update({
        where: { id },
        data: { status: MaintenanceStatus.CLOSED, closedAt: new Date() },
      });

      const vehicle = await tx.vehicle.findUnique({ where: { id: log.vehicleId } });

      // Don't resurrect a retired vehicle, and don't free a vehicle that still
      // has other open maintenance work outstanding.
      if (vehicle && vehicle.status !== VehicleStatus.RETIRED) {
        const otherOpen = await tx.maintenanceLog.count({
          where: { vehicleId: log.vehicleId, status: MaintenanceStatus.OPEN },
        });
        if (otherOpen === 0) {
          await tx.vehicle.update({
            where: { id: log.vehicleId },
            data: { status: VehicleStatus.AVAILABLE },
          });
        }
      }

      return closed;
    });
  },
};
