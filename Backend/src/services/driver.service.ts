import { Prisma } from "../generated/prisma/client";
import { prisma } from "../lib/prisma";
import { ApiError } from "../lib/ApiError";
import type { CreateDriverInput, ListDriversQuery, UpdateDriverInput } from "../schemas/driver.schema";

const DUPLICATE_LICENSE = "A driver with this license number already exists";

// P2002 = unique constraint violation (only `licenseNumber` is unique on Driver).
function isUniqueViolation(err: unknown): boolean {
  return err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002";
}

export const driverService = {
  async list({ status, q, page, limit }: ListDriversQuery) {
    const where: Prisma.DriverWhereInput = {
      ...(status && { status }),
      ...(q && {
        OR: [
          { name: { contains: q, mode: "insensitive" } },
          { licenseNumber: { contains: q, mode: "insensitive" } },
          { contactNumber: { contains: q } },
        ],
      }),
    };

    const [items, total] = await Promise.all([
      prisma.driver.findMany({
        where,
        orderBy: { createdAt: "desc" },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.driver.count({ where }),
    ]);

    return {
      items,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  },

  // Drivers whose license expires within `withinDays` from now, excluding
  // SUSPENDED drivers (they're not on active duty). Used by the daily
  // license-expiry reminder job. Soonest-to-expire first.
  async findExpiringLicenses(withinDays: number) {
    const now = new Date();
    const cutoff = new Date(now.getTime() + withinDays * 24 * 60 * 60 * 1000);

    return prisma.driver.findMany({
      where: {
        status: { not: "SUSPENDED" },
        licenseExpiryDate: { gte: now, lte: cutoff },
      },
      orderBy: { licenseExpiryDate: "asc" },
    });
  },

  async getById(id: string) {
    const driver = await prisma.driver.findUnique({ where: { id } });
    if (!driver) throw ApiError.notFound("Driver not found");
    return driver;
  },

  async create(input: CreateDriverInput) {
    try {
      return await prisma.driver.create({ data: input });
    } catch (err) {
      if (isUniqueViolation(err)) throw ApiError.conflict(DUPLICATE_LICENSE);
      throw err;
    }
  },

  async update(id: string, input: UpdateDriverInput) {
    await driverService.getById(id); // 404 if the driver doesn't exist
    try {
      return await prisma.driver.update({ where: { id }, data: input });
    } catch (err) {
      if (isUniqueViolation(err)) throw ApiError.conflict(DUPLICATE_LICENSE);
      throw err;
    }
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
