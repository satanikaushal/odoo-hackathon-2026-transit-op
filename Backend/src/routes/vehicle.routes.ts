import { Router } from "express";
import {
  createVehicle,
  deleteVehicle,
  getVehicle,
  getVehicleCosts,
  listVehicles,
  updateVehicle,
  updateVehicleStatus,
} from "../controllers/vehicle.controller";
import {
  deleteVehicleDocument,
  listVehicleDocuments,
  uploadVehicleDocument,
} from "../controllers/vehicleDocument.controller";
import { authenticate } from "../middleware/authenticate";
import { authorize } from "../middleware/authorize";
import { uploadDocumentFile } from "../middleware/upload";
import { validateBody, validateParams, validateQuery } from "../middleware/validate";
import { Role } from "../generated/prisma/enums";
import {
  createVehicleSchema,
  listVehiclesQuerySchema,
  updateVehicleSchema,
  updateVehicleStatusSchema,
  vehicleIdParamsSchema,
} from "../schemas/vehicle.schema";
import {
  uploadVehicleDocumentSchema,
  vehicleDocumentParamsSchema,
} from "../schemas/vehicleDocument.schema";

export const vehicleRouter = Router();

// The registry is master data: any authenticated user may read it, but only
// admins and fleet managers may create, modify, or delete vehicles.
const canManage = authorize(Role.ADMIN, Role.FLEET_MANAGER);

vehicleRouter.use(authenticate);

vehicleRouter.get("/", validateQuery(listVehiclesQuerySchema), listVehicles);
vehicleRouter.get("/:id", validateParams(vehicleIdParamsSchema), getVehicle);
vehicleRouter.get("/:id/costs", validateParams(vehicleIdParamsSchema), getVehicleCosts);

vehicleRouter.post("/", canManage, validateBody(createVehicleSchema), createVehicle);

vehicleRouter.patch(
  "/:id",
  canManage,
  validateParams(vehicleIdParamsSchema),
  validateBody(updateVehicleSchema),
  updateVehicle,
);

vehicleRouter.patch(
  "/:id/status",
  canManage,
  validateParams(vehicleIdParamsSchema),
  validateBody(updateVehicleStatusSchema),
  updateVehicleStatus,
);

vehicleRouter.delete("/:id", canManage, validateParams(vehicleIdParamsSchema), deleteVehicle);

// Vehicle documents (registration cert, insurance, permit, …). Multer must run
// before validateBody — multipart text fields only exist on req.body after it.
vehicleRouter.get("/:id/documents", validateParams(vehicleIdParamsSchema), listVehicleDocuments);
vehicleRouter.post(
  "/:id/documents",
  canManage,
  validateParams(vehicleIdParamsSchema),
  uploadDocumentFile,
  validateBody(uploadVehicleDocumentSchema),
  uploadVehicleDocument,
);
vehicleRouter.delete(
  "/:id/documents/:documentId",
  canManage,
  validateParams(vehicleDocumentParamsSchema),
  deleteVehicleDocument,
);
