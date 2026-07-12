import { Router } from "express";
import { healthRouter } from "./health.routes";
import { authRouter } from "./auth.routes";
import { dashboardRouter } from "./dashboard.routes";
import { vehicleRouter } from "./vehicle.routes";
import { driverRouter } from "./driver.routes";
import { tripRouter } from "./trip.routes";
import { maintenanceRouter } from "./maintenance.routes";
import { fuelLogRouter } from "./fuelLog.routes";
import { expenseRouter } from "./expense.routes";
import { reportRouter } from "./report.routes";

// Add new route groups here as the API grows.
export const router = Router();

router.use(healthRouter);
router.use("/api/auth", authRouter);
router.use("/api/dashboard", dashboardRouter);
router.use("/api/vehicles", vehicleRouter);
router.use("/api/drivers", driverRouter);
router.use("/api/trips", tripRouter);
router.use("/api/maintenance", maintenanceRouter);
router.use("/api/fuel-logs", fuelLogRouter);
router.use("/api/expenses", expenseRouter);
router.use("/api/reports", reportRouter);
