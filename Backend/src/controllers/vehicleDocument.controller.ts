import type { Request, Response } from "express";
import { created, ok } from "../lib/response";
import { ApiError } from "../lib/ApiError";
import { vehicleDocumentService } from "../services/vehicleDocument.service";
import type {
  UploadVehicleDocumentInput,
  VehicleDocumentParams,
} from "../schemas/vehicleDocument.schema";

export async function listVehicleDocuments(req: Request, res: Response) {
  const { id } = req.validated.params as { id: string };
  ok(res, await vehicleDocumentService.listByVehicle(id));
}

export async function uploadVehicleDocument(req: Request, res: Response) {
  const { id } = req.validated.params as { id: string };
  const input = req.validated.body as UploadVehicleDocumentInput;
  if (!req.file) throw ApiError.badRequest('A file is required (multipart field "file")');

  created(res, await vehicleDocumentService.create(id, input, req.file.filename));
}

export async function deleteVehicleDocument(req: Request, res: Response) {
  const { id, documentId } = req.validated.params as VehicleDocumentParams;
  await vehicleDocumentService.remove(id, documentId);
  res.status(204).send();
}
