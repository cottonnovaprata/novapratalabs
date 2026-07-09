#!/bin/bash
set -e

echo "==> Criando módulo Produtores no NovaPrata Labs"

# -----------------------------------------------------------------
# 1) SCHEMA PRISMA - adiciona os models novos
# -----------------------------------------------------------------
mkdir -p prisma
cat >> prisma/schema.prisma << 'NOVAPRATA_EOF'

model Produtor {
  id          String         @id @default(cuid())
  nome        String
  documento   String?
  telefone    String?
  email       String?
  whatsapp    String?
  status      String         @default("ativo")
  observacoes String?
  createdAt   DateTime       @default(now())
  updatedAt   DateTime       @updatedAt
  fazendas    Fazenda[]
  lotes       LoteColheita[]
}

model Fazenda {
  id         String    @id @default(cuid())
  nome       String
  produtorId String
  produtor   Produtor  @relation(fields: [produtorId], references: [id], onDelete: Cascade)
  talhoes    Talhao[]
  createdAt  DateTime  @default(now())
}

model Talhao {
  id           String   @id @default(cuid())
  nome         String
  areaHa       Float
  variedade    String
  areaDividida Boolean  @default(false)
  observacoes  String?
  safra        String   @default("2026")
  fazendaId    String
  fazenda      Fazenda  @relation(fields: [fazendaId], references: [id], onDelete: Cascade)
  createdAt    DateTime @default(now())
}

model LoteColheita {
  id            String    @id @default(cuid())
  numeroBloco   String?
  produtorId    String
  produtor      Produtor  @relation(fields: [produtorId], references: [id], onDelete: Cascade)
  talhao        String?
  dataColheita  DateTime?
  classificacao String?
  fardos        Int       @default(0)
  pesoTotalKg   Float     @default(0)
  status        String    @default("colhido")
  notaFiscal    String?
  observacoes   String?
  safra         String    @default("2026")
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
}
NOVAPRATA_EOF

echo "==> schema.prisma atualizado"

# -----------------------------------------------------------------
# 2) SQL MANUAL PARA RODAR NO NEON (você roda manual, como já faz)
# -----------------------------------------------------------------
mkdir -p prisma/manual-sql
cat > prisma/manual-sql/2026_produtores.sql << 'NOVAPRATA_EOF'
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
NOVAPRATA_EOF

echo "==> SQL manual criado em prisma/manual-sql/2026_produtores.sql"
echo "    (rode esse SQL direto no console do Neon antes do deploy)"

# -----------------------------------------------------------------
# 3) SEED - dados reais já coletados
# -----------------------------------------------------------------
cat > prisma/seed-produtores.ts << 'NOVAPRATA_EOF'
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  const andre = await prisma.produtor.upsert({
    where: { id: "produtor-andre-diogo-dalben" },
    update: {},
    create: {
      id: "produtor-andre-diogo-dalben",
      nome: "André Diogo Dalben",
      status: "ativo",
      fazendas: {
        create: {
          nome: "Fazenda principal",
          talhoes: {
            create: [
              { nome: "01 e 02", areaHa: 145.4, variedade: "FB 911" },
              { nome: "03", areaHa: 55.6, variedade: "FB 911" },
              { nome: "04", areaHa: 10, variedade: "FB 945" },
              { nome: "04", areaHa: 20, variedade: "FB 911" },
              { nome: "06", areaHa: 90, variedade: "FB 911" },
              { nome: "08", areaHa: 74, variedade: "DP 1949" },
            ],
          },
        },
      },
    },
  });

  const jose = await prisma.produtor.upsert({
    where: { id: "produtor-jose-olimpio-ascoli" },
    update: {},
    create: {
      id: "produtor-jose-olimpio-ascoli",
      nome: "José Olimpio Ascoli",
      status: "ativo",
      fazendas: {
        create: {
          nome: "Fazenda principal",
          talhoes: {
            create: [
              { nome: "1", areaHa: 25, variedade: "TMG 84" },
              {
                nome: "4",
                areaHa: 105,
                variedade: "IMA 712 e SA 2271",
                areaDividida: true,
                observacoes: "Área dividida entre as duas variedades",
              },
              { nome: "5", areaHa: 45, variedade: "Sem 2278 Dagma" },
              {
                nome: "7",
                areaHa: 95,
                variedade: "IMA 712 e 707",
                areaDividida: true,
                observacoes: "Área dividida entre as duas variedades",
              },
            ],
          },
        },
      },
    },
  });

  await prisma.produtor.upsert({
    where: { id: "produtor-itacir-jose-picinin" },
    update: {},
    create: {
      id: "produtor-itacir-jose-picinin",
      nome: "Itacir José Picinin",
      status: "pendente",
      observacoes:
        "Recebido plantio de SOJA das fazendas Boa Vista e Celeste - falta confirmar dados de ALGODÃO 2026",
    },
  });

  await prisma.produtor.upsert({
    where: { id: "produtor-francisco-alberto-lermen" },
    update: {},
    create: {
      id: "produtor-francisco-alberto-lermen",
      nome: "Francisco Alberto Lermen",
      status: "pendente",
      observacoes: "Dados de plantio 2026 ainda não recebidos",
    },
  });

  console.log("Seed concluído:", andre.nome, "/", jose.nome);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
NOVAPRATA_EOF

echo "==> Seed criado em prisma/seed-produtores.ts"

# -----------------------------------------------------------------
# 4) PÁGINA - LISTA DE PRODUTORES
# -----------------------------------------------------------------
mkdir -p app/produtores
cat > app/produtores/page.tsx << 'NOVAPRATA_EOF'
import Link from "next/link";
import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

function iniciais(nome: string) {
  return nome
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0])
    .join("")
    .toUpperCase();
}

export default async function ProdutoresPage() {
  const produtores = await prisma.produtor.findMany({
    include: { fazendas: { include: { talhoes: true } }, lotes: true },
    orderBy: { nome: "asc" },
  });

  return (
    <div className="p-6 md:p-8">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-medium text-zinc-900 dark:text-zinc-50">
            Produtores
          </h1>
          <p className="text-sm text-zinc-500">Safra 2026</p>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {produtores.map((p) => {
          const areaTotal = p.fazendas.reduce(
            (acc, f) => acc + f.talhoes.reduce((a, t) => a + t.areaHa, 0),
            0
          );
          const totalTalhoes = p.fazendas.reduce(
            (acc, f) => acc + f.talhoes.length,
            0
          );
          const fardos = p.lotes.reduce((acc, l) => acc + l.fardos, 0);

          const statusColor =
            p.status === "ativo"
              ? "bg-emerald-100 text-emerald-800"
              : "bg-amber-100 text-amber-800";

          return (
            <Link
              key={p.id}
              href={`/produtores/${p.id}`}
              className="rounded-xl border border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 p-5 hover:border-[#4f46e5] transition-colors"
            >
              <div className="flex items-center gap-3 mb-4">
                <div className="w-11 h-11 rounded-full bg-[#4f46e5] text-white flex items-center justify-center font-medium">
                  {iniciais(p.nome)}
                </div>
                <div className="min-w-0">
                  <p className="font-medium text-zinc-900 dark:text-zinc-50 truncate">
                    {p.nome}
                  </p>
                  <span
                    className={`text-xs px-2 py-0.5 rounded-md font-medium ${statusColor}`}
                  >
                    {p.status}
                  </span>
                </div>
              </div>
              <div className="grid grid-cols-3 gap-2 text-center text-sm">
                <div>
                  <p className="text-zinc-500 text-xs">Área</p>
                  <p className="font-medium">{areaTotal || "-"} ha</p>
                </div>
                <div>
                  <p className="text-zinc-500 text-xs">Talhões</p>
                  <p className="font-medium">{totalTalhoes || "-"}</p>
                </div>
                <div>
                  <p className="text-zinc-500 text-xs">Fardos</p>
                  <p className="font-medium">{fardos || "-"}</p>
                </div>
              </div>
            </Link>
          );
        })}
      </div>
    </div>
  );
}
NOVAPRATA_EOF

echo "==> app/produtores/page.tsx criado"

# -----------------------------------------------------------------
# 5) PÁGINA - FICHA DO PRODUTOR
# -----------------------------------------------------------------
mkdir -p "app/produtores/[id]"
cat > "app/produtores/[id]/page.tsx" << 'NOVAPRATA_EOF'
import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import ProdutorFicha from "@/components/produtores/ProdutorFicha";

export const dynamic = "force-dynamic";

export default async function ProdutorPage({
  params,
}: {
  params: { id: string };
}) {
  const produtor = await prisma.produtor.findUnique({
    where: { id: params.id },
    include: {
      fazendas: { include: { talhoes: true } },
      lotes: { orderBy: { createdAt: "desc" } },
    },
  });

  if (!produtor) notFound();

  return <ProdutorFicha produtor={produtor} />;
}
NOVAPRATA_EOF

echo "==> app/produtores/[id]/page.tsx criado"

# -----------------------------------------------------------------
# 6) COMPONENTE CLIENTE - ABAS DA FICHA
# -----------------------------------------------------------------
mkdir -p components/produtores
cat > components/produtores/ProdutorFicha.tsx << 'NOVAPRATA_EOF'
"use client";

import { useState } from "react";

type Talhao = {
  id: string;
  nome: string;
  areaHa: number;
  variedade: string;
  areaDividida: boolean;
  observacoes: string | null;
};

type Fazenda = {
  id: string;
  nome: string;
  talhoes: Talhao[];
};

type Lote = {
  id: string;
  numeroBloco: string | null;
  talhao: string | null;
  fardos: number;
  pesoTotalKg: number;
  status: string;
  dataColheita: string | null;
};

type Produtor = {
  id: string;
  nome: string;
  status: string;
  telefone: string | null;
  email: string | null;
  whatsapp: string | null;
  observacoes: string | null;
  fazendas: Fazenda[];
  lotes: Lote[];
};

const TABS = [
  "Dados gerais",
  "Fazendas e talhões",
  "Safras",
  "Colheita e lotes",
  "Documentos",
] as const;

function iniciais(nome: string) {
  return nome
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0])
    .join("")
    .toUpperCase();
}

export default function ProdutorFicha({ produtor }: { produtor: Produtor }) {
  const [tab, setTab] = useState<(typeof TABS)[number]>("Fazendas e talhões");

  const areaTotal = produtor.fazendas.reduce(
    (acc, f) => acc + f.talhoes.reduce((a, t) => a + t.areaHa, 0),
    0
  );
  const totalTalhoes = produtor.fazendas.reduce(
    (acc, f) => acc + f.talhoes.length,
    0
  );
  const fardos = produtor.lotes.reduce((acc, l) => acc + l.fardos, 0);

  const statusColor =
    produtor.status === "ativo"
      ? "bg-emerald-100 text-emerald-800"
      : "bg-amber-100 text-amber-800";

  return (
    <div className="p-6 md:p-8 max-w-4xl">
      <div className="rounded-xl border border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 p-5 mb-4 flex items-center justify-between flex-wrap gap-4">
        <div className="flex items-center gap-3">
          <div className="w-14 h-14 rounded-full bg-[#4f46e5] text-white flex items-center justify-center font-medium text-lg">
            {iniciais(produtor.nome)}
          </div>
          <div>
            <p className="font-medium text-lg text-zinc-900 dark:text-zinc-50">
              {produtor.nome}
            </p>
            <p className="text-sm text-zinc-500">Safra atual: 2026</p>
          </div>
        </div>
        <span className={`text-xs px-3 py-1 rounded-md font-medium ${statusColor}`}>
          {produtor.status}
        </span>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-4">
        {[
          { label: "Área total", value: areaTotal ? `${areaTotal} ha` : "-" },
          { label: "Fazendas", value: produtor.fazendas.length || "-" },
          { label: "Talhões", value: totalTalhoes || "-" },
          { label: "Fardos colhidos", value: fardos || "-" },
        ].map((m) => (
          <div
            key={m.label}
            className="rounded-lg bg-zinc-50 dark:bg-zinc-800/50 p-4"
          >
            <p className="text-xs text-zinc-500">{m.label}</p>
            <p className="text-xl font-medium mt-1">{m.value}</p>
          </div>
        ))}
      </div>

      <div className="flex gap-1 border-b border-zinc-200 dark:border-zinc-800 mb-4 overflow-x-auto">
        {TABS.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`px-3 py-2 text-sm whitespace-nowrap ${
              tab === t
                ? "font-medium text-[#4f46e5] border-b-2 border-[#4f46e5]"
                : "text-zinc-500"
            }`}
          >
            {t}
          </button>
        ))}
      </div>

      {tab === "Dados gerais" && (
        <div className="rounded-xl border border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 p-5 space-y-2 text-sm">
          <p><span className="text-zinc-500">Telefone: </span>{produtor.telefone || "-"}</p>
          <p><span className="text-zinc-500">E-mail: </span>{produtor.email || "-"}</p>
          <p><span className="text-zinc-500">WhatsApp: </span>{produtor.whatsapp || "-"}</p>
          <p><span className="text-zinc-500">Observações: </span>{produtor.observacoes || "-"}</p>
        </div>
      )}

      {tab === "Fazendas e talhões" && (
        <div className="space-y-4">
          {produtor.fazendas.length === 0 && (
            <p className="text-sm text-zinc-500">Nenhuma fazenda/talhão cadastrado ainda.</p>
          )}
          {produtor.fazendas.map((f) => (
            <div
              key={f.id}
              className="rounded-xl border border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 p-5"
            >
              <p className="font-medium mb-3">{f.nome}</p>
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-left text-zinc-500 border-b border-zinc-200 dark:border-zinc-800">
                    <th className="pb-2 font-normal">Talhão</th>
                    <th className="pb-2 font-normal">Área</th>
                    <th className="pb-2 font-normal">Variedade</th>
                  </tr>
                </thead>
                <tbody>
                  {f.talhoes.map((t) => (
                    <tr key={t.id} className="border-b border-zinc-100 dark:border-zinc-800/50 last:border-0">
                      <td className="py-2">{t.nome}</td>
                      <td className="py-2">{t.areaHa} ha</td>
                      <td className="py-2">
                        {t.variedade}
                        {t.areaDividida && (
                          <span className="ml-2 text-xs text-zinc-400">(área dividida)</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ))}
        </div>
      )}

      {tab === "Safras" && (
        <div className="rounded-xl border border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 p-5 text-sm text-zinc-500">
          Histórico multi-safra entra aqui quando tivermos mais de um ano cadastrado.
        </div>
      )}

      {tab === "Colheita e lotes" && (
        <div className="rounded-xl border border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 p-5">
          {produtor.lotes.length === 0 ? (
            <p className="text-sm text-zinc-500">Nenhum lote lançado ainda.</p>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-zinc-500 border-b border-zinc-200 dark:border-zinc-800">
                  <th className="pb-2 font-normal">Bloco</th>
                  <th className="pb-2 font-normal">Talhão</th>
                  <th className="pb-2 font-normal">Fardos</th>
                  <th className="pb-2 font-normal">Peso (kg)</th>
                  <th className="pb-2 font-normal">Status</th>
                </tr>
              </thead>
              <tbody>
                {produtor.lotes.map((l) => (
                  <tr key={l.id} className="border-b border-zinc-100 dark:border-zinc-800/50 last:border-0">
                    <td className="py-2">{l.numeroBloco || "-"}</td>
                    <td className="py-2">{l.talhao || "-"}</td>
                    <td className="py-2">{l.fardos}</td>
                    <td className="py-2">{l.pesoTotalKg}</td>
                    <td className="py-2">{l.status}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {tab === "Documentos" && (
        <div className="rounded-xl border border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 p-5 text-sm text-zinc-500">
          Upload de documentos entra aqui (contratos, CAR, notas).
        </div>
      )}
    </div>
  );
}
NOVAPRATA_EOF

echo "==> components/produtores/ProdutorFicha.tsx criado"

echo ""
echo "==================================================================="
echo "TUDO CRIADO. Próximos passos no Codespace:"
echo "1) Confira se prisma/schema.prisma já tem 'generator client' e"
echo "   'datasource db' configurados (não mexi nisso)."
echo "2) Rode o SQL em prisma/manual-sql/2026_produtores.sql no console"
echo "   do Neon (do jeito que você já faz nas migrações manuais)."
echo "3) npx prisma generate"
echo "4) npx tsx prisma/seed-produtores.ts   (ou: npx ts-node ...)"
echo "5) npm run dev  -> acesse /produtores"
echo "6) git add . && git commit -m 'feat: modulo produtores 2026' && git push"
echo "==================================================================="
