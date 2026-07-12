import { z } from "zod";

// Multipart text fields arrive as strings; the file itself is handled by the
// upload middleware, not Zod.
export const uploadVehicleDocumentSchema = z.object({
  type: z.string().trim().min(1, "Document type is required").max(60),
  expiryDate: z.coerce.date().optional(),
});
export type UploadVehicleDocumentInput = z.infer<typeof uploadVehicleDocumentSchema>;

export const vehicleDocumentParamsSchema = z.object({
  id: z.string().min(1),
  documentId: z.string().min(1),
});
export type VehicleDocumentParams = z.infer<typeof vehicleDocumentParamsSchema>;
