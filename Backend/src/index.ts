import { env } from "./config/env";
import { logger } from "./lib/logger";
import { createApp } from "./app";
import { startLicenseReminders } from "./jobs/licenseReminder.job";

const app = createApp();

app.listen(env.PORT, () => {
  logger.info(`Server running at http://localhost:${env.PORT}`);
});

// Background jobs live here (not in app.ts) so they run only in the server
// process, not when the app is imported for tests. startLicenseReminders is
// idempotent and guarded against duplicate --hot reloads.
startLicenseReminders().catch((err) => {
  logger.error({ err }, "failed to start license-reminder job");
});
