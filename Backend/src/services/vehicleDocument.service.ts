import { unlink } from "node:fs/promises";
import path from "node:path";
import { prisma } from "../lib/prisma";
import { ApiError } from "../lib/ApiError";
import { UPLOAD_DIR } from "../middleware/upload";
import type { UploadVehicleDocumentInput } from "../schemas/vehicleDocument.schema";

async function assertVehicleExists(vehicleId: string) {
  const vehicle = await prisma.vehicle.findUnique({ where: { id: vehicleId }, select: { id: true } });
  if (!vehicle) throw ApiError.notFound("Vehicle not found");
}

export const vehicleDocumentService = {
  async listByVehicle(vehicleId: string) {
    await assertVehicleExists(vehicleId);
    return prisma.vehicleDocument.findMany({
      where: { vehicleId },
      orderBy: { createdAt: "desc" },
    });
  },

  async create(vehicleId: string, input: UploadVehicleDocumentInput, storedFilename: string) {
    await assertVehicleExists(vehicleId);
    return prisma.vehicleDocument.create({
      data: {
        vehicleId,
        type: input.type,
        expiryDate: input.expiryDate,
        fileUrl: `/uploads/vehicle-documents/${storedFilename}`,
      },
    });
  },

  async remove(vehicleId: string, documentId: string) {
    const document = await prisma.vehicleDocument.findUnique({ where: { id: documentId } });
    if (!document || document.vehicleId !== vehicleId) {
      throw ApiError.notFound("Document not found");
    }

    await prisma.vehicleDocument.delete({ where: { id: documentId } });

    // Best-effort disk cleanup — the DB row is the source of truth, a stray
    // file on disk is harmless.
    const filename = path.basename(document.fileUrl);
    await unlink(path.join(UPLOAD_DIR, filename)).catch(() => {});
  },
};
