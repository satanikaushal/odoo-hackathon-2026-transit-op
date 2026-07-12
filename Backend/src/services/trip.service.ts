import { Prisma, DriverStatus, TripStatus, VehicleStatus } from "../generated/prisma/client";
import { prisma } from "../lib/prisma";
import { ApiError } from "../lib/ApiError";
import type { CompleteTripInput, CreateTripInput, ListTripsQuery } from "../schemas/trip.schema";

// A Prisma transaction client — the subset of `prisma` available inside
// `$transaction(async (tx) => ...)`.
type Tx = Prisma.TransactionClient;

// Assert that a vehicle may be put on a trip. Centralised so `create` and
// `dispatch` enforce identical rules (dispatch re-checks at commit time to
// close the race between drafting and dispatching).
function assertVehicleAssignable(vehicle: { status: VehicleStatus }) {
  switch (vehicle.status) {
    case VehicleStatus.AVAILABLE:
      return;
    case VehicleStatus.ON_TRIP:
      throw ApiError.conflict("Vehicle is already on a trip and cannot be assigned to another");
    case VehicleStatus.IN_SHOP:
      throw ApiError.conflict("Vehicle is in the shop and cannot be dispatched");
    case VehicleStatus.RETIRED:
      throw ApiError.conflict("Vehicle is retired and cannot be dispatched");
  }
}

// Assert that a driver may be assigned: available status + a license that has
// not expired. Suspended / on-trip / off-duty drivers are all rejected.
function assertDriverAssignable(driver: { status: DriverStatus; licenseExpiryDate: Date }) {
  switch (driver.status) {
    case DriverStatus.AVAILABLE:
      break;
    case DriverStatus.ON_TRIP:
      throw ApiError.conflict("Driver is already on a trip and cannot be assigned to another");
    case DriverStatus.SUSPENDED:
      throw ApiError.conflict("Driver is suspended and cannot be assigned to trips");
    case DriverStatus.OFF_DUTY:
      throw ApiError.conflict("Driver is off duty and cannot be assigned to trips");
  }

  if (driver.licenseExpiryDate.getTime() <= Date.now()) {
    throw ApiError.badRequest("Driver's license has expired and cannot be assigned to trips");
  }
}

function assertCargoWithinCapacity(cargoWeight: number, maxLoadCapacity: number) {
  if (cargoWeight > maxLoadCapacity) {
    throw ApiError.badRequest(
      `Cargo weight (${cargoWeight}) exceeds the vehicle's maximum load capacity (${maxLoadCapacity})`,
    );
  }
}

export const tripService = {
  async list({ status, vehicleId, driverId, search, page, limit }: ListTripsQuery) {
    const where: Prisma.TripWhereInput = {
      ...(status && { status }),
      ...(vehicleId && { vehicleId }),
      ...(driverId && { driverId }),
      ...(search && {
        OR: [
          { source: { contains: search, mode: "insensitive" } },
          { destination: { contains: search, mode: "insensitive" } },
        ],
      }),
    };

    const [items, total] = await Promise.all([
      prisma.trip.findMany({
        where,
        orderBy: { createdAt: "desc" },
        skip: (page - 1) * limit,
        take: limit,
        include: {
          vehicle: { select: { id: true, registrationNumber: true, name: true, status: true } },
          driver: { select: { id: true, name: true, licenseNumber: true, status: true } },
        },
      }),
      prisma.trip.count({ where }),
    ]);

    return {
      items,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  },

  async getById(id: string) {
    const trip = await prisma.trip.findUnique({
      where: { id },
      include: { vehicle: true, driver: true },
    });
    if (!trip) throw ApiError.notFound("Trip not found");
    return trip;
  },

  // Create a trip in DRAFT. Validates eligibility but does NOT flip
  // vehicle/driver status — that happens on dispatch. `createdById` is the
  // authenticated user drafting the trip.
  async create(input: CreateTripInput, createdById: string) {
    const [vehicle, driver] = await Promise.all([
      prisma.vehicle.findUnique({ where: { id: input.vehicleId } }),
      prisma.driver.findUnique({ where: { id: input.driverId } }),
    ]);

    if (!vehicle) throw ApiError.notFound("Vehicle not found");
    if (!driver) throw ApiError.notFound("Driver not found");

    assertVehicleAssignable(vehicle);
    assertDriverAssignable(driver);
    assertCargoWithinCapacity(input.cargoWeight, vehicle.maxLoadCapacity);

    return prisma.trip.create({
      data: {
        source: input.source,
        destination: input.destination,
        vehicleId: input.vehicleId,
        driverId: input.driverId,
        cargoWeight: input.cargoWeight,
        plannedDistance: input.plannedDistance,
        status: TripStatus.DRAFT,
        createdById,
      },
    });
  },

  // DRAFT → DISPATCHED. Re-checks eligibility inside the transaction so two
  // drafts competing for the same vehicle/driver can't both dispatch, and flips
  // both vehicle and driver to ON_TRIP atomically.
  async dispatch(id: string) {
    return prisma.$transaction(async (tx: Tx) => {
      const trip = await tx.trip.findUnique({ where: { id } });
      if (!trip) throw ApiError.notFound("Trip not found");
      if (trip.status !== TripStatus.DRAFT) {
        throw ApiError.conflict(`Only draft trips can be dispatched (trip is ${trip.status})`);
      }

      const [vehicle, driver] = await Promise.all([
        tx.vehicle.findUnique({ where: { id: trip.vehicleId } }),
        tx.driver.findUnique({ where: { id: trip.driverId } }),
      ]);
      if (!vehicle) throw ApiError.notFound("Vehicle not found");
      if (!driver) throw ApiError.notFound("Driver not found");

      assertVehicleAssignable(vehicle);
      assertDriverAssignable(driver);
      assertCargoWithinCapacity(trip.cargoWeight, vehicle.maxLoadCapacity);

      await Promise.all([
        tx.vehicle.update({ where: { id: vehicle.id }, data: { status: VehicleStatus.ON_TRIP } }),
        tx.driver.update({ where: { id: driver.id }, data: { status: DriverStatus.ON_TRIP } }),
      ]);

      return tx.trip.update({
        where: { id },
        data: { status: TripStatus.DISPATCHED, dispatchedAt: new Date() },
      });
    });
  },

  // DISPATCHED → COMPLETED. Frees the vehicle and driver, writes the final
  // odometer back onto the vehicle, and records the trip's actual outcome.
  async complete(id: string, input: CompleteTripInput) {
    return prisma.$transaction(async (tx: Tx) => {
      const trip = await tx.trip.findUnique({ where: { id } });
      if (!trip) throw ApiError.notFound("Trip not found");
      if (trip.status !== TripStatus.DISPATCHED) {
        throw ApiError.conflict(`Only dispatched trips can be completed (trip is ${trip.status})`);
      }

      const vehicle = await tx.vehicle.findUnique({ where: { id: trip.vehicleId } });
      if (!vehicle) throw ApiError.notFound("Vehicle not found");

      if (input.finalOdometer < vehicle.odometer) {
        throw ApiError.badRequest(
          `Final odometer (${input.finalOdometer}) cannot be less than the vehicle's current reading (${vehicle.odometer})`,
        );
      }
      const actualDistance = input.finalOdometer - vehicle.odometer;

      await Promise.all([
        tx.vehicle.update({
          where: { id: trip.vehicleId },
          data: { status: VehicleStatus.AVAILABLE, odometer: input.finalOdometer },
        }),
        tx.driver.update({
          where: { id: trip.driverId },
          data: { status: DriverStatus.AVAILABLE },
        }),
      ]);

      return tx.trip.update({
        where: { id },
        data: {
          status: TripStatus.COMPLETED,
          completedAt: new Date(),
          finalOdometer: input.finalOdometer,
          actualDistance,
          ...(input.fuelConsumed !== undefined && { fuelConsumed: input.fuelConsumed }),
          ...(input.revenue !== undefined && { revenue: input.revenue }),
        },
      });
    });
  },

  // Cancel a trip. A DRAFT has no side effects to undo; a DISPATCHED trip
  // restores its vehicle and driver to AVAILABLE. Completed or already-cancelled
  // trips cannot be cancelled.
  async cancel(id: string) {
    return prisma.$transaction(async (tx: Tx) => {
      const trip = await tx.trip.findUnique({ where: { id } });
      if (!trip) throw ApiError.notFound("Trip not found");

      if (trip.status === TripStatus.COMPLETED || trip.status === TripStatus.CANCELLED) {
        throw ApiError.conflict(`A ${trip.status.toLowerCase()} trip cannot be cancelled`);
      }

      if (trip.status === TripStatus.DISPATCHED) {
        await Promise.all([
          tx.vehicle.update({
            where: { id: trip.vehicleId },
            data: { status: VehicleStatus.AVAILABLE },
          }),
          tx.driver.update({
            where: { id: trip.driverId },
            data: { status: DriverStatus.AVAILABLE },
          }),
        ]);
      }

      return tx.trip.update({
        where: { id },
        data: { status: TripStatus.CANCELLED, cancelledAt: new Date() },
      });
    });
  },
};
