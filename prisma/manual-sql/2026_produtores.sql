CREATE TABLE IF NOT EXISTS "Produtor" (
  "id" TEXT PRIMARY KEY,
  "nome" TEXT NOT NULL,
  "documento" TEXT,
  "telefone" TEXT,
  "email" TEXT,
  "whatsapp" TEXT,
  "status" TEXT NOT NULL DEFAULT 'ativo',
  "observacoes" TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
  "updatedAt" TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "Fazenda" (
  "id" TEXT PRIMARY KEY,
  "nome" TEXT NOT NULL,
  "produtorId" TEXT NOT NULL REFERENCES "Produtor"("id") ON DELETE CASCADE,
  "createdAt" TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "Talhao" (
  "id" TEXT PRIMARY KEY,
  "nome" TEXT NOT NULL,
  "areaHa" DOUBLE PRECISION NOT NULL,
  "variedade" TEXT NOT NULL,
  "areaDividida" BOOLEAN NOT NULL DEFAULT false,
  "observacoes" TEXT,
  "safra" TEXT NOT NULL DEFAULT '2026',
  "fazendaId" TEXT NOT NULL REFERENCES "Fazenda"("id") ON DELETE CASCADE,
  "createdAt" TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "LoteColheita" (
  "id" TEXT PRIMARY KEY,
  "numeroBloco" TEXT,
  "produtorId" TEXT NOT NULL REFERENCES "Produtor"("id") ON DELETE CASCADE,
  "talhao" TEXT,
  "dataColheita" TIMESTAMP,
  "classificacao" TEXT,
  "fardos" INTEGER NOT NULL DEFAULT 0,
  "pesoTotalKg" DOUBLE PRECISION NOT NULL DEFAULT 0,
  "status" TEXT NOT NULL DEFAULT 'colhido',
  "notaFiscal" TEXT,
  "observacoes" TEXT,
  "safra" TEXT NOT NULL DEFAULT '2026',
  "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
  "updatedAt" TIMESTAMP NOT NULL DEFAULT now()
);
