import type { Prisma } from "../generated/prisma/client";
import { prisma } from "../lib/prisma";
import { ApiError } from "../lib/ApiError";
import type { CreateExpenseInput, ListExpensesQuery } from "../schemas/expense.schema";

const vehicleIdentity = {
  select: { id: true, registrationNumber: true, name: true, status: true },
} as const;

// A trip-attributed expense must belong to the same vehicle (mirrors fuelLog).
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

export const expenseService = {
  async create(input: CreateExpenseInput) {
    await assertVehicleAndTrip(input.vehicleId, input.tripId);

    return prisma.expense.create({
      data: {
        vehicleId: input.vehicleId,
        tripId: input.tripId,
        category: input.category,
        amount: input.amount,
        description: input.description,
        ...(input.date && { date: input.date }),
      },
    });
  },

  async list({ vehicleId, tripId, category, page, limit }: ListExpensesQuery) {
    const where: Prisma.ExpenseWhereInput = {
      ...(vehicleId && { vehicleId }),
      ...(tripId && { tripId }),
      ...(category && { category }),
    };

    const [items, total] = await Promise.all([
      prisma.expense.findMany({
        where,
        orderBy: { date: "desc" },
        skip: (page - 1) * limit,
        take: limit,
        include: { vehicle: vehicleIdentity },
      }),
      prisma.expense.count({ where }),
    ]);

    return {
      items,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  },

  async getById(id: string) {
    const expense = await prisma.expense.findUnique({
      where: { id },
      include: { vehicle: vehicleIdentity },
    });
    if (!expense) throw ApiError.notFound("Expense not found");
    return expense;
  },
};
