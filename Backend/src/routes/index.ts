import { Router } from "express";
import { healthRouter } from "./health.routes";
import { authRouter } from "./auth.routes";
import { driverRouter } from "./driver.routes";
import { reportRouter } from "./report.routes";

// Add new route groups here as the API grows.
export const router = Router();

router.use(healthRouter);
router.use("/api/auth", authRouter);
router.use("/api/drivers", driverRouter);
router.use("/api/reports", reportRouter);
