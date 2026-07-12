import { Router } from "express";
import { login, logout, me, refresh } from "../controllers/auth.controller";
import { authenticate } from "../middleware/authenticate";
import { authRateLimiter } from "../middleware/rateLimit";
import { validateBody } from "../middleware/validate";
import { loginSchema, refreshSchema } from "../schemas/auth.schema";

export const authRouter = Router();

// Tight per-IP cap on the unauthenticated credential endpoints to blunt
// brute-forcing (complements the per-account lockout in auth.service.ts).
authRouter.post("/login", authRateLimiter, validateBody(loginSchema), login);
authRouter.post("/refresh", authRateLimiter, validateBody(refreshSchema), refresh);
authRouter.post("/logout", validateBody(refreshSchema), logout);
authRouter.get("/me", authenticate, me);
