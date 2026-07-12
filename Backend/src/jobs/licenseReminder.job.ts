import { Queue, Worker, type Job } from "bullmq";
import { redisConnection } from "../lib/redis";
import { logger } from "../lib/logger";
import { mailer } from "../lib/mailer";
import { env } from "../config/env";
import { prisma } from "../lib/prisma";
import { driverService } from "../services/driver.service";

export const LICENSE_REMINDER_QUEUE = "license-reminder";
// Stable scheduler id — `upsertJobScheduler` is keyed on it, so re-running the
// bootstrap (e.g. on `--hot` reload or redeploy) replaces the schedule instead
// of stacking duplicates.
const SCHEDULER_ID = "license-reminder-daily";

const log = logger.child({ job: LICENSE_REMINDER_QUEUE });

// The queue handle used both to enqueue the repeatable job and, if ever needed,
// to enqueue an ad-hoc run.
export const licenseReminderQueue = new Queue(LICENSE_REMINDER_QUEUE, {
  connection: redisConnection,
});

function formatDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

// The actual work: find drivers with soon-to-expire licenses and email a digest
// to each fleet manager / admin. Drivers themselves have no email on record
// (only a contact number), so managers are the recipients.
async function processLicenseReminders(job: Job): Promise<{ drivers: number; sent: number; failed: number }> {
  const drivers = await driverService.findExpiringLicenses(env.LICENSE_REMINDER_DAYS);

  if (drivers.length === 0) {
    log.info({ jobId: job.id }, "no licenses expiring within window; nothing to send");
    return { drivers: 0, sent: 0, failed: 0 };
  }

  const recipients = await prisma.user.findMany({
    where: { isActive: true, role: { in: ["ADMIN", "FLEET_MANAGER"] } },
    select: { email: true, name: true },
  });

  if (recipients.length === 0) {
    log.warn(
      { jobId: job.id, drivers: drivers.length },
      "licenses expiring but no active ADMIN/FLEET_MANAGER to notify",
    );
    return { drivers: drivers.length, sent: 0, failed: 0 };
  }

  const lines = drivers.map(
    (d) => `- ${d.name} (license ${d.licenseNumber}) expires ${formatDate(d.licenseExpiryDate)}`,
  );
  const subject = `${drivers.length} driver license(s) expiring within ${env.LICENSE_REMINDER_DAYS} days`;
  const text = [
    `The following driver licenses expire within the next ${env.LICENSE_REMINDER_DAYS} days:`,
    "",
    ...lines,
    "",
    "Please arrange renewals.",
  ].join("\n");

  let sent = 0;
  let failed = 0;

  // Send per-recipient. One failed email must not abort the whole job or block
  // the remaining recipients.
  for (const recipient of recipients) {
    try {
      await mailer.send({ to: recipient.email, subject, text });
      sent += 1;
    } catch (err) {
      failed += 1;
      log.error(
        { jobId: job.id, to: recipient.email, err },
        "failed to send license-expiry reminder",
      );
    }
  }

  log.info(
    { jobId: job.id, drivers: drivers.length, recipients: recipients.length, sent, failed },
    "license-expiry reminders processed",
  );
  return { drivers: drivers.length, sent, failed };
}

// Started once per process. Guarded via globalThis so `--hot` reloads don't
// spin up a second worker consuming from the same queue.
const globalForWorker = globalThis as unknown as { licenseReminderWorker?: Worker };

export async function startLicenseReminders(): Promise<void> {
  if (!env.ENABLE_JOBS) {
    log.info("ENABLE_JOBS=false — skipping license-reminder worker/scheduler");
    return;
  }

  if (!globalForWorker.licenseReminderWorker) {
    const worker = new Worker(LICENSE_REMINDER_QUEUE, processLicenseReminders, {
      connection: redisConnection,
    });
    worker.on("failed", (job, err) => {
      log.error({ jobId: job?.id, err }, "license-reminder job failed");
    });
    worker.on("error", (err) => {
      log.error({ err }, "license-reminder worker error");
    });
    globalForWorker.licenseReminderWorker = worker;
  }

  // Idempotent: keyed on SCHEDULER_ID, so this replaces (not duplicates) the
  // repeatable schedule across reloads/redeploys.
  await licenseReminderQueue.upsertJobScheduler(
    SCHEDULER_ID,
    { pattern: env.LICENSE_REMINDER_CRON },
    { name: "scan-and-notify" },
  );

  log.info(
    { cron: env.LICENSE_REMINDER_CRON, withinDays: env.LICENSE_REMINDER_DAYS },
    "license-reminder scheduler active",
  );
}
