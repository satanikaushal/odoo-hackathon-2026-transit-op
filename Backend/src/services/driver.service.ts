import type { Prisma } from "../generated/prisma/client";
import { prisma } from "../lib/prisma";
import { ApiError } from "../lib/ApiError";
import type { CreateDriverInput, ListDriversQuery, UpdateDriverInput } from "../schemas/driver.schema";

// Duplicate licenseNumber (P2002) is mapped centrally in errorHandler.ts
// (PLAN.md §9.2) — no per-call try/catch needed here.

export const driverService = {
  async list({ status, q, sortBy, sortDir }: ListDriversQuery) {
    return prisma.driver.findMany({
      where: {
        ...(status && { status }),
        ...(q && {
          OR: [
            { name: { contains: q, mode: "insensitive" } },
            { licenseNumber: { contains: q, mode: "insensitive" } },
            { contactNumber: { contains: q } },
          ],
        }),
      },
      orderBy: { [sortBy]: sortDir } as Prisma.DriverOrderByWithRelationInput,
    });
  },

  async getById(id: string) {
    const driver = await prisma.driver.findUnique({ where: { id } });
    if (!driver) throw ApiError.notFound("Driver not found");
    return driver;
  },

  async create(input: CreateDriverInput) {
    return prisma.driver.create({ data: input });
  },

  async update(id: string, input: UpdateDriverInput) {
    await driverService.getById(id); // 404 if the driver doesn't exist
    return prisma.driver.update({ where: { id }, data: input });
  },

  async remove(id: string) {
    await driverService.getById(id); // 404 if the driver doesn't exist

    // Trips reference the driver with a required FK, so a hard delete would be
    // blocked by the DB. Refuse up front with a helpful message rather than
    // leaking a raw foreign-key error.
    const tripCount = await prisma.trip.count({ where: { driverId: id } });
    if (tripCount > 0) {
      throw ApiError.conflict(
        "Driver has associated trips and cannot be deleted; set status to SUSPENDED or OFF_DUTY instead",
      );
    }

    await prisma.driver.delete({ where: { id } });
  },
};
