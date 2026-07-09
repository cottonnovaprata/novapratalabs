-- Módulo Produtores - safra 2026 (script único, idempotente)

CREATE TABLE IF NOT EXISTS "producers" (
  "id" TEXT PRIMARY KEY,
  "name" TEXT NOT NULL,
  "document" TEXT,
  "stateRegistration" TEXT,
  "address" TEXT,
  "phone" TEXT,
  "email" TEXT,
  "whatsapp" TEXT,
  "status" TEXT NOT NULL DEFAULT 'ativo',
  "notes" TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
  "updatedAt" TIMESTAMP NOT NULL DEFAULT now()
);

-- Garante as colunas novas mesmo se a tabela já existia antes (sem IE/endereço)
ALTER TABLE "producers" ADD COLUMN IF NOT EXISTS "stateRegistration" TEXT;
ALTER TABLE "producers" ADD COLUMN IF NOT EXISTS "address" TEXT;

CREATE TABLE IF NOT EXISTS "farms" (
  "id" TEXT PRIMARY KEY,
  "name" TEXT NOT NULL,
  "producerId" TEXT NOT NULL REFERENCES "producers"("id") ON DELETE CASCADE,
  "createdAt" TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "plots" (
  "id" TEXT PRIMARY KEY,
  "name" TEXT NOT NULL,
  "areaHa" DOUBLE PRECISION NOT NULL,
  "variety" TEXT NOT NULL,
  "splitArea" BOOLEAN NOT NULL DEFAULT false,
  "notes" TEXT,
  "season" TEXT NOT NULL DEFAULT '2026',
  "farmId" TEXT NOT NULL REFERENCES "farms"("id") ON DELETE CASCADE,
  "createdAt" TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "harvest_lots" (
  "id" TEXT PRIMARY KEY,
  "blockNumber" TEXT,
  "producerId" TEXT NOT NULL REFERENCES "producers"("id") ON DELETE CASCADE,
  "plot" TEXT,
  "harvestDate" TIMESTAMP,
  "classification" TEXT,
  "bales" INTEGER NOT NULL DEFAULT 0,
  "totalWeightKg" DOUBLE PRECISION NOT NULL DEFAULT 0,
  "status" TEXT NOT NULL DEFAULT 'colhido',
  "invoiceNumber" TEXT,
  "notes" TEXT,
  "season" TEXT NOT NULL DEFAULT '2026',
  "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
  "updatedAt" TIMESTAMP NOT NULL DEFAULT now()
);

-- Limpeza: remove tabelas de uma tentativa antiga (nomes em português), se existirem
DROP TABLE IF EXISTS "LoteColheita";
DROP TABLE IF EXISTS "Talhao";
DROP TABLE IF EXISTS "Fazenda";
DROP TABLE IF EXISTS "Produtor";
