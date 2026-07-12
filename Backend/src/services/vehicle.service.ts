import { prisma } from "../lib/prisma";
import { ApiError } from "../lib/ApiError";
import type { Prisma } from "../generated/prisma/client";
import type {
  CreateVehicleInput,
  ListVehiclesQuery,
  UpdateVehicleInput,
} from "../schemas/vehicle.schema";
import type { VehicleStatus } from "../generated/prisma/enums";

// P2003 = foreign-key violation. Unique violations (P2002) are mapped
// centrally in errorHandler.ts (PLAN.md §9.2).
const FK_VIOLATION = "P2003";

function hasCode(error: unknown): error is { code: string } {
  return typeof error === "object" && error !== null && "code" in error;
}

export const vehicleService = {
  async create(input: CreateVehicleInput) {
    return prisma.vehicle.create({ data: input });
  },

  async list(query: ListVehiclesQuery) {
    const { status, type, region, search, sortBy, sortDir, page, limit } = query;

    const where: Prisma.VehicleWhereInput = {
      ...(status && { status }),
      ...(type && { type }),
      ...(region && { region }),
      ...(search && {
        OR: [
          { registrationNumber: { contains: search, mode: "insensitive" } },
          { name: { contains: search, mode: "insensitive" } },
        ],
      }),
    };

    const [items, total] = await Promise.all([
      prisma.vehicle.findMany({
        where,
        orderBy: { [sortBy]: sortDir } as Prisma.VehicleOrderByWithRelationInput,
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.vehicle.count({ where }),
    ]);

    return {
      items,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  },

  async getById(id: string) {
    const vehicle = await prisma.vehicle.findUnique({ where: { id } });
    if (!vehicle) throw ApiError.notFound("Vehicle not found");
    return vehicle;
  },

  async update(id: string, input: UpdateVehicleInput) {
    // Surface a clean 404 rather than Prisma's P2025 on a missing record.
    await this.getById(id);
    return prisma.vehicle.update({ where: { id }, data: input });
  },

  async updateStatus(id: string, status: VehicleStatus) {
    await this.getById(id);
    return prisma.vehicle.update({ where: { id }, data: { status } });
  },

  async remove(id: string) {
    await this.getById(id);
    try {
      await prisma.vehicle.delete({ where: { id } });
    } catch (error) {
      // Deliberately overrides the central P2003 mapping: this one can point
      // the caller at the supported alternative (retire, don't delete).
      if (hasCode(error) && error.code === FK_VIOLATION) {
        throw ApiError.conflict(
          "Vehicle has related trips or logs and cannot be deleted; set its status to RETIRED instead",
        );
      }
      throw error;
    }
  },
};
