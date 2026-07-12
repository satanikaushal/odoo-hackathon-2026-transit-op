import { prisma } from "../lib/prisma";
import { ApiError } from "../lib/ApiError";
import type { Prisma } from "../generated/prisma/client";
import type {
  CreateVehicleInput,
  ListVehiclesQuery,
  UpdateVehicleInput,
} from "../schemas/vehicle.schema";
import type { VehicleStatus } from "../generated/prisma/enums";

// Prisma known-request error codes we care about here.
const UNIQUE_VIOLATION = "P2002";
const FK_VIOLATION = "P2003";

function hasCode(error: unknown): error is { code: string } {
  return typeof error === "object" && error !== null && "code" in error;
}

export const vehicleService = {
  async create(input: CreateVehicleInput) {
    try {
      return await prisma.vehicle.create({ data: input });
    } catch (error) {
      if (hasCode(error) && error.code === UNIQUE_VIOLATION) {
        throw ApiError.conflict(
          `A vehicle with registration number "${input.registrationNumber}" already exists`,
        );
      }
      throw error;
    }
  },

  async list(query: ListVehiclesQuery) {
    const { status, type, region, search, page, limit } = query;

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
        orderBy: { createdAt: "desc" },
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

    try {
      return await prisma.vehicle.update({ where: { id }, data: input });
    } catch (error) {
      if (hasCode(error) && error.code === UNIQUE_VIOLATION) {
        throw ApiError.conflict(
          `A vehicle with registration number "${input.registrationNumber}" already exists`,
        );
      }
      throw error;
    }
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
      if (hasCode(error) && error.code === FK_VIOLATION) {
        throw ApiError.conflict(
          "Vehicle has related trips or logs and cannot be deleted; set its status to RETIRED instead",
        );
      }
      throw error;
    }
  },
};
