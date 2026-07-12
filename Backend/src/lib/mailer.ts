import nodemailer, { type Transporter } from "nodemailer";
import { env } from "../config/env";
import { logger } from "./logger";

export interface MailMessage {
  to: string;
  subject: string;
  text: string;
  html?: string;
}

// Common contract every mailer implementation satisfies. Depend on this
// interface (not a concrete class) so callers can be handed a mock in tests.
export interface Mailer {
  send(message: MailMessage): Promise<void>;
}

// Dev/test mailer: never sends real email — logs what would have been sent and
// records it on `sent` so tests can assert against it.
export class LogMailer implements Mailer {
  readonly sent: MailMessage[] = [];

  async send(message: MailMessage): Promise<void> {
    this.sent.push(message);
    logger.info(
      { to: message.to, subject: message.subject },
      "mailer (log-only): would have sent email",
    );
  }

  // Convenience for tests that reuse a single instance across cases.
  clear(): void {
    this.sent.length = 0;
  }
}

// Production mailer over SMTP via nodemailer. `send` throws on transport
// failure so callers can decide whether to swallow it (e.g. per-recipient
// loops that must not abort the whole job).
export class SmtpMailer implements Mailer {
  private readonly transporter: Transporter;

  constructor() {
    if (!env.SMTP_HOST) {
      throw new Error("SmtpMailer requires SMTP_HOST to be set");
    }
    this.transporter = nodemailer.createTransport({
      host: env.SMTP_HOST,
      port: env.SMTP_PORT,
      secure: env.SMTP_SECURE,
      auth: env.SMTP_USER ? { user: env.SMTP_USER, pass: env.SMTP_PASS } : undefined,
    });
  }

  async send(message: MailMessage): Promise<void> {
    await this.transporter.sendMail({ from: env.MAIL_FROM, ...message });
    logger.info({ to: message.to, subject: message.subject }, "email sent");
  }
}

// Pick the implementation for this process. Only production with SMTP
// configured sends real email; everything else logs.
function createMailer(): Mailer {
  if (env.isProduction && env.SMTP_HOST) {
    return new SmtpMailer();
  }
  if (env.isProduction) {
    logger.warn("SMTP_HOST not set in production — falling back to log-only mailer");
  }
  return new LogMailer();
}

export const mailer: Mailer = createMailer();
