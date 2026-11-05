-- 第一版记录表；标识符由 Prisma 客户端生成。
CREATE TABLE "Note" (
  "id" UUID NOT NULL,
  "title" VARCHAR(120) NOT NULL,
  "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Note_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "Note_createdAt_idx" ON "Note"("createdAt");
