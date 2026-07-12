import { prisma } from "../src/lib/prisma";

const SEED_USERS = [
  { name: "Admin", email: "admin@transitops.dev", role: "ADMIN" as const },
  { name: "Fleet Manager", email: "fleet.manager@transitops.dev", role: "FLEET_MANAGER" as const },
  { name: "Dispatcher", email: "dispatcher@transitops.dev", role: "DRIVER" as const },
  { name: "Safety Officer", email: "safety.officer@transitops.dev", role: "SAFETY_OFFICER" as const },
  { name: "Financial Analyst", email: "financial.analyst@transitops.dev", role: "FINANCIAL_ANALYST" as const },
];

const SEED_PASSWORD = "Password123!";

async function main() {
  const passwordHash = await Bun.password.hash(SEED_PASSWORD);

  for (const user of SEED_USERS) {
    await prisma.user.upsert({
      where: { email: user.email },
      update: {},
      create: { ...user, passwordHash },
    });
  }

  console.log(`Seeded ${SEED_USERS.length} users. Password for all: ${SEED_PASSWORD}`);
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
