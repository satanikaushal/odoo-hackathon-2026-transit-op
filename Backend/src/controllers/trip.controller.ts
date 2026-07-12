import type { Request, Response } from "express";
import { created, ok } from "../lib/response";
import { reqLogger } from "../lib/logger";
import { tripService } from "../services/trip.service";
import type {
  CompleteTripInput,
  CreateTripInput,
  ListTripsQuery,
  TripIdParam,
} from "../schemas/trip.schema";

export async function listTrips(req: Request, res: Response) {
  const query = req.validated.query as ListTripsQuery;
  const result = await tripService.list(query);
  reqLogger(req).debug(
    { filters: query, returned: result.items.length, total: result.pagination.total },
    "listed trips",
  );
  ok(res, result);
}

export async function getTrip(req: Request, res: Response) {
  const { id } = req.validated.params as TripIdParam;
  const trip = await tripService.getById(id);
  reqLogger(req).debug({ tripId: id }, "fetched trip");
  ok(res, trip);
}

export async function createTrip(req: Request, res: Response) {
  const input = req.validated.body as CreateTripInput;
  // The authenticated user drafting the trip is recorded as its creator.
  const trip = await tripService.create(input, req.user!.sub);
  reqLogger(req).info(
    { tripId: trip.id, vehicleId: trip.vehicleId, driverId: trip.driverId, status: trip.status },
    "trip created",
  );
  created(res, trip, "Trip created");
}

export async function dispatchTrip(req: Request, res: Response) {
  const { id } = req.validated.params as TripIdParam;
  const trip = await tripService.dispatch(id);
  reqLogger(req).info(
    { tripId: trip.id, vehicleId: trip.vehicleId, driverId: trip.driverId, status: trip.status },
    "trip dispatched; vehicle and driver set ON_TRIP",
  );
  ok(res, trip, 200, "Trip dispatched");
}

export async function completeTrip(req: Request, res: Response) {
  const { id } = req.validated.params as TripIdParam;
  const input = req.validated.body as CompleteTripInput;
  const trip = await tripService.complete(id, input);
  reqLogger(req).info(
    { tripId: trip.id, vehicleId: trip.vehicleId, driverId: trip.driverId, finalOdometer: trip.finalOdometer, status: trip.status },
    "trip completed; vehicle and driver released to AVAILABLE",
  );
  ok(res, trip, 200, "Trip completed");
}

export async function cancelTrip(req: Request, res: Response) {
  const { id } = req.validated.params as TripIdParam;
  const trip = await tripService.cancel(id);
  reqLogger(req).info(
    { tripId: trip.id, vehicleId: trip.vehicleId, driverId: trip.driverId, status: trip.status },
    "trip cancelled",
  );
  ok(res, trip, 200, "Trip cancelled");
}
