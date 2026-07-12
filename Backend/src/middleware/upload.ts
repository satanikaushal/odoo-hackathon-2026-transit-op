import { randomUUID } from "node:crypto";
import { mkdirSync } from "node:fs";
import path from "node:path";
import type { NextFunction, Request, Response } from "express";
import multer from "multer";
import { ApiError } from "../lib/ApiError";

export const UPLOAD_DIR = path.join(process.cwd(), "uploads", "vehicle-documents");
mkdirSync(UPLOAD_DIR, { recursive: true });

// Extension whitelist doubles as the filename sanitizer: the stored name is a
// random UUID plus one of these suffixes, so client-supplied names (and any
// path-traversal attempts in them) never reach the filesystem.
const ALLOWED_EXTENSIONS = new Set([".pdf", ".png", ".jpg", ".jpeg", ".webp"]);
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5 MB

const storage = multer.diskStorage({
  destination: UPLOAD_DIR,
  filename: (_req, file, cb) => {
    cb(null, `${randomUUID()}${path.extname(file.originalname).toLowerCase()}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: MAX_FILE_SIZE },
  fileFilter: (_req, file, cb) => {
    if (!ALLOWED_EXTENSIONS.has(path.extname(file.originalname).toLowerCase())) {
      return cb(
        ApiError.badRequest(
          `Unsupported file type — allowed: ${[...ALLOWED_EXTENSIONS].join(", ")}`,
        ),
      );
    }
    cb(null, true);
  },
});

// Wraps multer so its errors (size limit, unexpected field) surface as 400s
// through the normal error handler instead of opaque 500s.
export function uploadDocumentFile(req: Request, res: Response, next: NextFunction) {
  upload.single("file")(req, res, (err: unknown) => {
    if (err instanceof multer.MulterError) return next(ApiError.badRequest(err.message));
    next(err);
  });
}
