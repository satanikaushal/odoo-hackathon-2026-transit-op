import "express-serve-static-core";
import type { AccessTokenPayload } from "../lib/jwt";

declare module "express-serve-static-core" {
  interface Request {
    validated: {
      body?: unknown;
      params?: unknown;
      query?: unknown;
    };
    user?: AccessTokenPayload;
  }
}
