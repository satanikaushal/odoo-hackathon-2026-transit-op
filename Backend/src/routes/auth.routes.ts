import { Router } from "express";
import { login, logout, me, refresh } from "../controllers/auth.controller";
import { authenticate } from "../middleware/authenticate";
import { validateBody } from "../middleware/validate";
import { loginSchema, refreshSchema } from "../schemas/auth.schema";

export const authRouter = Router();

authRouter.post("/login", validateBody(loginSchema), login);
authRouter.post("/refresh", validateBody(refreshSchema), refresh);
authRouter.post("/logout", validateBody(refreshSchema), logout);
authRouter.get("/me", authenticate, me);
