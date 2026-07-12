import { Router } from "express";
import { healthRouter } from "./health.routes";
import { authRouter } from "./auth.routes";

// Add new route groups here as the API grows.
export const router = Router();

router.use(healthRouter);
router.use("/api/auth", authRouter);
