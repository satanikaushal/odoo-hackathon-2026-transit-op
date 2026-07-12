-- CreateEnum
CREATE TYPE "DeviceType" AS ENUM ('ANDROID', 'IOS');

-- AlterTable
ALTER TABLE "RefreshToken" ADD COLUMN     "deviceToken" TEXT,
ADD COLUMN     "deviceType" "DeviceType";
