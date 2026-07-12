import { randomBytes } from "node:crypto";
import { prisma } from "../src/lib/prisma";

const SEED_USERS = [
  { name: "Admin", email: "admin@transitops.dev", role: "ADMIN" as const },
  { name: "Fleet Manager", email: "fleet.manager@transitops.dev", role: "FLEET_MANAGER" as const },
  { name: "Dispatcher", email: "dispatcher@transitops.dev", role: "DRIVER" as const },
  { name: "Safety Officer", email: "safety.officer@transitops.dev", role: "SAFETY_OFFICER" as const },
  { name: "Financial Analyst", email: "financial.analyst@transitops.dev", role: "FINANCIAL_ANALYST" as const },
];

function generatePassword(): string {
  return randomBytes(12).toString("base64url");
}

async function main() {
  const credentials: { email: string; password: string }[] = [];

  for (const user of SEED_USERS) {
    const existing = await prisma.user.findUnique({ where: { email: user.email } });
    if (existing) {
      console.log(`- ${user.email} already exists, leaving password untouched`);
      continue;
    }

    const password = generatePassword();
    const passwordHash = await Bun.password.hash(password);
    await prisma.user.create({ data: { ...user, passwordHash } });
    credentials.push({ email: user.email, password });
  }

  if (credentials.length === 0) {
    console.log("No new users created.");
    return;
  }

  console.log("\nSeeded users — save these now, passwords are never stored or shown again:\n");
  for (const { email, password } of credentials) {
    console.log(`  ${email}\t${password}`);
  }
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
