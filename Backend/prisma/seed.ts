import { randomBytes } from "node:crypto";
import { prisma } from "../src/lib/prisma";

const SEED_USERS = [
  { name: "Admin", email: "admin@transitops.dev", role: "ADMIN" as const },
  { name: "Fleet Manager", email: "fleet.manager@transitops.dev", role: "FLEET_MANAGER" as const },
  { name: "Dispatcher", email: "dispatcher@transitops.dev", role: "DRIVER" as const },
  { name: "Safety Officer", email: "safety.officer@transitops.dev", role: "SAFETY_OFFICER" as const },
  { name: "Financial Analyst", email: "financial.analyst@transitops.dev", role: "FINANCIAL_ANALYST" as const },
];

// Sample fleet — covers the states the trip/maintenance rules branch on:
// available (dispatchable), in-shop and retired (must NOT be dispatchable).
const SEED_VEHICLES = [
  { registrationNumber: "MH12AB1001", name: "Tata Prima Hauler", type: "Truck", maxLoadCapacity: 10000, odometer: 52000, acquisitionCost: "3500000.00", status: "AVAILABLE" as const, region: "West" },
  { registrationNumber: "MH12AB1002", name: "Ashok Leyland Boss", type: "Truck", maxLoadCapacity: 5000, odometer: 18000, acquisitionCost: "2200000.00", status: "AVAILABLE" as const, region: "West" },
  { registrationNumber: "DL01CV2001", name: "Mahindra Delivery Van", type: "Van", maxLoadCapacity: 1500, odometer: 9000, acquisitionCost: "900000.00", status: "IN_SHOP" as const, region: "North" },
  { registrationNumber: "KA05RT3001", name: "Old Eicher (Retired)", type: "Truck", maxLoadCapacity: 8000, odometer: 480000, acquisitionCost: "1500000.00", status: "RETIRED" as const, region: "South" },
];

// Sample drivers — an assignable one plus the two ineligibility cases the trip
// rules must reject (expired license, suspended).
const SEED_DRIVERS = [
  { name: "Ravi Kumar", licenseNumber: "DL-VALID-001", licenseCategory: "HMV", licenseExpiryDate: new Date("2030-12-31"), contactNumber: "+91-9000000001", status: "AVAILABLE" as const },
  { name: "Suresh Patil", licenseNumber: "DL-VALID-002", licenseCategory: "HMV", licenseExpiryDate: new Date("2029-06-30"), contactNumber: "+91-9000000002", status: "AVAILABLE" as const },
  { name: "Expired Ex-driver", licenseNumber: "DL-EXPIRED-003", licenseCategory: "LMV", licenseExpiryDate: new Date("2020-01-01"), contactNumber: "+91-9000000003", status: "AVAILABLE" as const },
  { name: "Suspended Sam", licenseNumber: "DL-SUSPEND-004", licenseCategory: "HMV", licenseExpiryDate: new Date("2031-01-01"), contactNumber: "+91-9000000004", status: "SUSPENDED" as const },
];

function generatePassword(): string {
  return randomBytes(12).toString("base64url");
}

async function seedUsers() {
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

async function seedVehicles() {
  for (const vehicle of SEED_VEHICLES) {
    const existing = await prisma.vehicle.findUnique({
      where: { registrationNumber: vehicle.registrationNumber },
    });
    if (existing) {
      console.log(`- vehicle ${vehicle.registrationNumber} already exists, skipping`);
      continue;
    }
    await prisma.vehicle.create({ data: vehicle });
    console.log(`+ vehicle ${vehicle.registrationNumber} (${vehicle.status})`);
  }
}

async function seedDrivers() {
  for (const driver of SEED_DRIVERS) {
    const existing = await prisma.driver.findUnique({
      where: { licenseNumber: driver.licenseNumber },
    });
    if (existing) {
      console.log(`- driver ${driver.licenseNumber} already exists, skipping`);
      continue;
    }
    await prisma.driver.create({ data: driver });
    console.log(`+ driver ${driver.name} (${driver.status})`);
  }
}

async function main() {
  await seedUsers();
  await seedVehicles();
  await seedDrivers();
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
