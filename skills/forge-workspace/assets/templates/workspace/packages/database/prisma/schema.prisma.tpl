generator client {
  provider            = "prisma-client"
  output              = "../src/generated/prisma"
  moduleFormat        = "esm"
  importFileExtension = "js"
}

datasource db {
  provider = "postgresql"
}

model Note {
  id        String   @id @default(uuid()) @db.Uuid
  title     String   @db.VarChar(120)
  createdAt DateTime @default(now()) @db.Timestamptz(3)

  @@index([createdAt])
}
