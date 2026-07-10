#!/bin/bash
set -e
echo "==> Módulo Produtores - versão final (CRUD + auditoria v2 + upload de documentos)"

# 0) Limpeza de tentativas antigas / scripts soltos na raiz
rm -rf app/produtores components/produtores 'src/app/(dashboard)/produtores' src/components/features/produtores 2>/dev/null || true
rm -f prisma/manual-sql/2026_produtores.sql prisma/manual-sql/2026_producers.sql prisma/manual-sql/2026_producers_v2_campos.sql 2>/dev/null || true
rm -f prisma/seed-produtores.ts 2>/dev/null || true
rm -f modulo_produtores_completo*.sh produtores_crud_completo*.sh produtores_auditado_final.sh produtores_auditado_v2.sh 2>/dev/null || true

# 1) Schema Prisma - idempotente
python3 << 'PYPATCH'
path = 'prisma/schema.prisma'
with open(path, encoding='utf-8') as f:
    content = f.read()

import re
old_block_pattern = re.compile(r'model Produtor \{.*?^\}\n\nmodel Fazenda \{.*?^\}\n\nmodel Talhao \{.*?^\}\n\nmodel LoteColheita \{.*?^\}\n\n', re.DOTALL | re.MULTILINE)
content, n = old_block_pattern.subn('', content)
if n:
    print(f'==> removidos {n} bloco(s) de models antigos em portugues')

if 'model Producer ' not in content and 'model Producer {' not in content:
    content = content.rstrip('\n') + '\n' + '\nmodel Producer {\n  id                String   @id @default(cuid())\n  name              String\n  document          String?\n  stateRegistration String?\n  address           String?\n  phone             String?\n  email             String?\n  whatsapp          String?\n  status            String   @default("ativo")\n  notes             String?\n  createdAt         DateTime @default(now())\n  updatedAt         DateTime @updatedAt\n\n  farms        Farm[]\n  harvestLots  HarvestLot[]\n  documents    ProducerDocument[]\n\n  @@map("producers")\n}\n\nmodel Farm {\n  id          String   @id @default(cuid())\n  name        String\n  producerId  String\n  producer    Producer @relation(fields: [producerId], references: [id], onDelete: Cascade)\n  plots       Plot[]\n  createdAt   DateTime @default(now())\n\n  @@map("farms")\n}\n\nmodel Plot {\n  id           String   @id @default(cuid())\n  name         String\n  areaHa       Float\n  variety      String\n  splitArea    Boolean  @default(false)\n  notes        String?\n  season       String   @default("2026")\n  farmId       String\n  farm         Farm     @relation(fields: [farmId], references: [id], onDelete: Cascade)\n  createdAt    DateTime @default(now())\n\n  @@map("plots")\n}\n\nmodel HarvestLot {\n  id            String    @id @default(cuid())\n  blockNumber   String?\n  producerId    String\n  producer      Producer  @relation(fields: [producerId], references: [id], onDelete: Cascade)\n  plot          String?\n  harvestDate   DateTime?\n  classification String?\n  bales         Int       @default(0)\n  totalWeightKg Float     @default(0)\n  status        String    @default("colhido")\n  invoiceNumber String?\n  notes         String?\n  season        String    @default("2026")\n  createdAt     DateTime  @default(now())\n  updatedAt     DateTime  @updatedAt\n\n  @@map("harvest_lots")\n}\n\nmodel ProducerDocument {\n  id         String   @id @default(cuid())\n  producerId String\n  producer   Producer @relation(fields: [producerId], references: [id], onDelete: Cascade)\n  fileName   String\n  mimeType   String\n  fileSize   Int\n  fileData   String   @db.Text\n  uploadedAt DateTime @default(now())\n\n  @@map("producer_documents")\n}\n'
    print('==> models Producer/Farm/Plot/HarvestLot/ProducerDocument adicionados')
else:
    if 'stateRegistration' not in content:
        old_head = '''model Producer {
  id           String   @id @default(cuid())
  name         String
  document     String?
  phone        String?
  email        String?
  whatsapp     String?
  status       String   @default("ativo")
  notes        String?
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt'''
        new_head = '''model Producer {
  id                String   @id @default(cuid())
  name              String
  document          String?
  stateRegistration String?
  address           String?
  phone             String?
  email             String?
  whatsapp          String?
  status            String   @default("ativo")
  notes             String?
  createdAt         DateTime @default(now())
  updatedAt         DateTime @updatedAt'''
        if old_head in content:
            content = content.replace(old_head, new_head)
            print('==> model Producer expandido com stateRegistration/address')
    if 'model ProducerDocument' not in content:
        doc_block = '''model ProducerDocument {
  id         String   @id @default(cuid())
  producerId String
  producer   Producer @relation(fields: [producerId], references: [id], onDelete: Cascade)
  fileName   String
  mimeType   String
  fileSize   Int
  fileData   String   @db.Text
  uploadedAt DateTime @default(now())

  @@map("producer_documents")
}

'''
        content = content.rstrip('\n') + '\n\n' + doc_block
        if 'documents    ProducerDocument[]' not in content:
            content = content.replace(
                '  farms        Farm[]\n  harvestLots  HarvestLot[]\n',
                '  farms        Farm[]\n  harvestLots  HarvestLot[]\n  documents    ProducerDocument[]\n'
            )
        print('==> model ProducerDocument adicionado')
    else:
        print('==> schema já está completo, nada a mudar')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
PYPATCH

mkdir -p "prisma/manual-sql"
cat > "prisma/manual-sql/producers_module.sql" << 'NOVAPRATA_EOF'
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

CREATE TABLE IF NOT EXISTS "producer_documents" (
  "id" TEXT PRIMARY KEY,
  "producerId" TEXT NOT NULL REFERENCES "producers"("id") ON DELETE CASCADE,
  "fileName" TEXT NOT NULL,
  "mimeType" TEXT NOT NULL,
  "fileSize" INTEGER NOT NULL,
  "fileData" TEXT NOT NULL,
  "uploadedAt" TIMESTAMP NOT NULL DEFAULT now()
);

-- Limpeza: remove tabelas de uma tentativa antiga (nomes em português), se existirem
DROP TABLE IF EXISTS "LoteColheita";
DROP TABLE IF EXISTS "Talhao";
DROP TABLE IF EXISTS "Fazenda";
DROP TABLE IF EXISTS "Produtor";
NOVAPRATA_EOF
echo "==> prisma/manual-sql/producers_module.sql escrito"

mkdir -p "prisma"
cat > "prisma/seed-producers.ts" << 'NOVAPRATA_EOF'
import { PrismaClient } from "@prisma/client"

const prisma = new PrismaClient()

async function main() {
  await prisma.producer.upsert({
    where: { id: "producer-andre-diogo-dalben" },
    update: {},
    create: {
      id: "producer-andre-diogo-dalben",
      name: "André Diogo Dalben",
      status: "ativo",
      farms: {
        create: {
          name: "Fazenda principal",
          plots: {
            create: [
              { name: "01 e 02", areaHa: 145.4, variety: "FB 911" },
              { name: "03", areaHa: 55.6, variety: "FB 911" },
              { name: "04", areaHa: 10, variety: "FB 945" },
              { name: "04", areaHa: 20, variety: "FB 911" },
              { name: "06", areaHa: 90, variety: "FB 911" },
              { name: "08", areaHa: 74, variety: "DP 1949" },
            ],
          },
        },
      },
    },
  })

  await prisma.producer.upsert({
    where: { id: "producer-jose-olimpio-ascoli" },
    update: {},
    create: {
      id: "producer-jose-olimpio-ascoli",
      name: "José Olimpio Ascoli",
      status: "ativo",
      farms: {
        create: {
          name: "Fazenda principal",
          plots: {
            create: [
              { name: "1", areaHa: 25, variety: "TMG 84" },
              {
                name: "4",
                areaHa: 105,
                variety: "IMA 712 e SA 2271",
                splitArea: true,
                notes: "Área dividida entre as duas variedades",
              },
              { name: "5", areaHa: 45, variety: "Sem 2278 Dagma" },
              {
                name: "7",
                areaHa: 95,
                variety: "IMA 712 e 707",
                splitArea: true,
                notes: "Área dividida entre as duas variedades",
              },
            ],
          },
        },
      },
    },
  })

  await prisma.producer.upsert({
    where: { id: "producer-itacir-jose-picinin" },
    update: {},
    create: {
      id: "producer-itacir-jose-picinin",
      name: "Itacir José Picinin",
      status: "pendente",
      notes:
        "Recebido plantio de SOJA das fazendas Boa Vista e Celeste - falta confirmar dados de ALGODÃO 2026",
    },
  })

  await prisma.producer.upsert({
    where: { id: "producer-francisco-alberto-lermen" },
    update: {},
    create: {
      id: "producer-francisco-alberto-lermen",
      name: "Francisco Alberto Lermen",
      status: "pendente",
      notes: "Dados de plantio 2026 ainda não recebidos",
    },
  })

  console.log("Seed de produtores concluído")
}

main()
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
NOVAPRATA_EOF
echo "==> prisma/seed-producers.ts escrito"

mkdir -p "src/app/api/producers"
cat > "src/app/api/producers/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function GET() {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const producers = await prisma.producer.findMany({
      include: {
        farms: { include: { plots: true } },
        harvestLots: true,
      },
      orderBy: { name: "asc" },
    })
    return NextResponse.json(producers)
  } catch (error) {
    console.error("Error fetching producers:", error)
    return NextResponse.json({ error: "Failed to fetch producers" }, { status: 500 })
  }
}

export async function POST(request: Request) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const body = await request.json()
    const { name, document, stateRegistration, address, phone, email, whatsapp, status, notes } = body

    if (!name) {
      return NextResponse.json({ error: "Nome é obrigatório" }, { status: 400 })
    }

    const producer = await prisma.producer.create({
      data: {
        name,
        document: document || null,
        stateRegistration: stateRegistration || null,
        address: address || null,
        phone: phone || null,
        email: email || null,
        whatsapp: whatsapp || null,
        status: status || "ativo",
        notes: notes || null,
      },
    })

    return NextResponse.json(producer)
  } catch (error) {
    console.error("Error creating producer:", error)
    return NextResponse.json({ error: "Failed to create producer" }, { status: 500 })
  }
}
NOVAPRATA_EOF
echo "==> src/app/api/producers/route.ts escrito"

mkdir -p "src/app/api/producers/[id]"
cat > "src/app/api/producers/[id]/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    const producer = await prisma.producer.findUnique({
      where: { id },
      include: {
        farms: { include: { plots: true } },
        harvestLots: { orderBy: { createdAt: "desc" } },
        documents: { orderBy: { uploadedAt: "desc" }, select: { id: true, fileName: true, mimeType: true, fileSize: true, uploadedAt: true } },
      },
    })

    if (!producer) {
      return NextResponse.json({ error: "Produtor não encontrado" }, { status: 404 })
    }

    return NextResponse.json(producer)
  } catch (error) {
    console.error("Error fetching producer:", error)
    return NextResponse.json({ error: "Failed to fetch producer" }, { status: 500 })
  }
}

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    const body = await request.json()
    const { name, document, stateRegistration, address, phone, email, whatsapp, status, notes } = body

    const producer = await prisma.producer.update({
      where: { id },
      data: {
        name,
        document: document || null,
        stateRegistration: stateRegistration || null,
        address: address || null,
        phone: phone || null,
        email: email || null,
        whatsapp: whatsapp || null,
        status: status || "ativo",
        notes: notes || null,
      },
    })

    return NextResponse.json(producer)
  } catch (error) {
    console.error("Error updating producer:", error)
    return NextResponse.json({ error: "Failed to update producer" }, { status: 500 })
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    await prisma.producer.delete({ where: { id } })
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("Error deleting producer:", error)
    return NextResponse.json({ error: "Failed to delete producer" }, { status: 500 })
  }
}
NOVAPRATA_EOF
echo "==> src/app/api/producers/[id]/route.ts escrito"

mkdir -p "src/app/api/producers/[id]/farms"
cat > "src/app/api/producers/[id]/farms/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    const body = await request.json()
    const { name } = body

    if (!name) {
      return NextResponse.json({ error: "Nome da fazenda é obrigatório" }, { status: 400 })
    }

    const farm = await prisma.farm.create({
      data: { name, producerId: id },
    })

    return NextResponse.json(farm)
  } catch (error) {
    console.error("Error creating farm:", error)
    return NextResponse.json({ error: "Failed to create farm" }, { status: 500 })
  }
}
NOVAPRATA_EOF
echo "==> src/app/api/producers/[id]/farms/route.ts escrito"

mkdir -p "src/app/api/producers/[id]/harvest-lots"
cat > "src/app/api/producers/[id]/harvest-lots/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    const body = await request.json()
    const { blockNumber, plot, harvestDate, classification, bales, totalWeightKg, status, invoiceNumber, notes, season } = body

    const lot = await prisma.harvestLot.create({
      data: {
        blockNumber: blockNumber || null,
        producerId: id,
        plot: plot || null,
        harvestDate: harvestDate ? new Date(harvestDate) : null,
        classification: classification || null,
        bales: Number(bales) || 0,
        totalWeightKg: Number(totalWeightKg) || 0,
        status: status || "colhido",
        invoiceNumber: invoiceNumber || null,
        notes: notes || null,
        season: season || "2026",
      },
    })

    return NextResponse.json(lot)
  } catch (error) {
    console.error("Error creating harvest lot:", error)
    return NextResponse.json({ error: "Failed to create harvest lot" }, { status: 500 })
  }
}
NOVAPRATA_EOF
echo "==> src/app/api/producers/[id]/harvest-lots/route.ts escrito"

mkdir -p "src/app/api/producers/[id]/documents"
cat > "src/app/api/producers/[id]/documents/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

const MAX_FILE_SIZE_BYTES = 4 * 1024 * 1024 // 4MB (limite prático do body em serverless functions)

export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    const body = await request.json()
    const { fileName, mimeType, fileData } = body

    if (!fileName || !mimeType || !fileData) {
      return NextResponse.json({ error: "Arquivo inválido" }, { status: 400 })
    }

    const sizeBytes = Math.ceil((fileData.length * 3) / 4)
    if (sizeBytes > MAX_FILE_SIZE_BYTES) {
      return NextResponse.json({ error: "Arquivo maior que 4MB não é suportado" }, { status: 413 })
    }

    const producer = await prisma.producer.findUnique({ where: { id } })
    if (!producer) {
      return NextResponse.json({ error: "Produtor não encontrado" }, { status: 404 })
    }

    const doc = await prisma.producerDocument.create({
      data: {
        producerId: id,
        fileName,
        mimeType,
        fileSize: sizeBytes,
        fileData,
      },
      select: { id: true, fileName: true, mimeType: true, fileSize: true, uploadedAt: true },
    })

    return NextResponse.json(doc)
  } catch (error) {
    console.error("Error uploading document:", error)
    return NextResponse.json({ error: "Failed to upload document" }, { status: 500 })
  }
}
NOVAPRATA_EOF
echo "==> src/app/api/producers/[id]/documents/route.ts escrito"

mkdir -p "src/app/api/producer-documents/[id]"
cat > "src/app/api/producer-documents/[id]/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    const doc = await prisma.producerDocument.findUnique({ where: { id } })
    if (!doc) {
      return NextResponse.json({ error: "Documento não encontrado" }, { status: 404 })
    }

    const buffer = Buffer.from(doc.fileData, "base64")
    return new NextResponse(new Uint8Array(buffer), {
      status: 200,
      headers: {
        "Content-Type": doc.mimeType,
        "Content-Disposition": `attachment; filename="${doc.fileName}"`,
        "Cache-Control": "no-store",
      },
    })
  } catch (error) {
    console.error("Error downloading document:", error)
    return NextResponse.json({ error: "Failed to download document" }, { status: 500 })
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    await prisma.producerDocument.delete({ where: { id } })
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("Error deleting document:", error)
    return NextResponse.json({ error: "Failed to delete document" }, { status: 500 })
  }
}
NOVAPRATA_EOF
echo "==> src/app/api/producer-documents/[id]/route.ts escrito"

mkdir -p "src/app/api/producers/export"
cat > "src/app/api/producers/export/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import ExcelJS from "exceljs"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export const runtime = "nodejs"
export const dynamic = "force-dynamic"

export async function GET() {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const producers = await prisma.producer.findMany({
      include: {
        farms: { include: { plots: true } },
        harvestLots: true,
      },
      orderBy: { name: "asc" },
    })

    const workbook = new ExcelJS.Workbook()

    const producersSheet = workbook.addWorksheet("Produtores")
    producersSheet.addRow([
      "Nome", "CPF/CNPJ", "Inscrição Estadual", "Status", "Telefone", "E-mail", "WhatsApp",
      "Área total (ha)", "Fazendas", "Talhões", "Fardos colhidos",
    ])
    for (const p of producers) {
      const areaTotal = p.farms.reduce((acc, f) => acc + f.plots.reduce((a, t) => a + t.areaHa, 0), 0)
      const totalPlots = p.farms.reduce((acc, f) => acc + f.plots.length, 0)
      const bales = p.harvestLots.reduce((acc, l) => acc + l.bales, 0)
      producersSheet.addRow([
        p.name, p.document || "", p.stateRegistration || "", p.status, p.phone || "", p.email || "", p.whatsapp || "",
        areaTotal, p.farms.length, totalPlots, bales,
      ])
    }
    producersSheet.getRow(1).font = { bold: true }
    producersSheet.columns.forEach((col) => { col.width = 22 })

    const plotsSheet = workbook.addWorksheet("Fazendas e Talhões")
    plotsSheet.addRow(["Produtor", "Fazenda", "Talhão", "Área (ha)", "Variedade", "Área dividida", "Safra"])
    for (const p of producers) {
      for (const f of p.farms) {
        for (const t of f.plots) {
          plotsSheet.addRow([p.name, f.name, t.name, t.areaHa, t.variety, t.splitArea ? "Sim" : "Não", t.season])
        }
      }
    }
    plotsSheet.getRow(1).font = { bold: true }
    plotsSheet.columns.forEach((col) => { col.width = 22 })

    const lotsSheet = workbook.addWorksheet("Colheita e Lotes")
    lotsSheet.addRow(["Produtor", "Bloco", "Talhão", "Data colheita", "Classificação", "Fardos", "Peso total (kg)", "Status", "Nota fiscal"])
    for (const p of producers) {
      for (const l of p.harvestLots) {
        lotsSheet.addRow([
          p.name, l.blockNumber || "", l.plot || "",
          l.harvestDate ? new Date(l.harvestDate).toLocaleDateString("pt-BR") : "",
          l.classification || "", l.bales, l.totalWeightKg, l.status, l.invoiceNumber || "",
        ])
      }
    }
    lotsSheet.getRow(1).font = { bold: true }
    lotsSheet.columns.forEach((col) => { col.width = 20 })

    const buffer = await workbook.xlsx.writeBuffer()
    const filename = `produtores-safra-2026-${new Date().toISOString().slice(0, 10)}.xlsx`

    return new NextResponse(new Uint8Array(buffer), {
      status: 200,
      headers: {
        "Content-Type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "Content-Disposition": `attachment; filename="${filename}"`,
        "Cache-Control": "no-store",
      },
    })
  } catch (error) {
    console.error("Error exporting producers:", error)
    return NextResponse.json({ error: "Failed to export producers" }, { status: 500 })
  }
}
NOVAPRATA_EOF
echo "==> src/app/api/producers/export/route.ts escrito"

mkdir -p "src/app/api/farms/[id]"
cat > "src/app/api/farms/[id]/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    const body = await request.json()
    const { name } = body

    const farm = await prisma.farm.update({
      where: { id },
      data: { name },
    })

    return NextResponse.json(farm)
  } catch (error) {
    console.error("Error updating farm:", error)
    return NextResponse.json({ error: "Failed to update farm" }, { status: 500 })
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    await prisma.farm.delete({ where: { id } })
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("Error deleting farm:", error)
    return NextResponse.json({ error: "Failed to delete farm" }, { status: 500 })
  }
}
NOVAPRATA_EOF
echo "==> src/app/api/farms/[id]/route.ts escrito"

mkdir -p "src/app/api/farms/[id]/plots"
cat > "src/app/api/farms/[id]/plots/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    const body = await request.json()
    const { name, areaHa, variety, splitArea, notes, season } = body

    if (!name || !areaHa || !variety) {
      return NextResponse.json({ error: "Talhão, área e variedade são obrigatórios" }, { status: 400 })
    }

    const plot = await prisma.plot.create({
      data: {
        name,
        areaHa: Number(areaHa),
        variety,
        splitArea: !!splitArea,
        notes: notes || null,
        season: season || "2026",
        farmId: id,
      },
    })

    return NextResponse.json(plot)
  } catch (error) {
    console.error("Error creating plot:", error)
    return NextResponse.json({ error: "Failed to create plot" }, { status: 500 })
  }
}
NOVAPRATA_EOF
echo "==> src/app/api/farms/[id]/plots/route.ts escrito"

mkdir -p "src/app/api/plots/[id]"
cat > "src/app/api/plots/[id]/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    const body = await request.json()
    const { name, areaHa, variety, splitArea, notes, season } = body

    const plot = await prisma.plot.update({
      where: { id },
      data: {
        name,
        areaHa: Number(areaHa),
        variety,
        splitArea: !!splitArea,
        notes: notes || null,
        season: season || "2026",
      },
    })

    return NextResponse.json(plot)
  } catch (error) {
    console.error("Error updating plot:", error)
    return NextResponse.json({ error: "Failed to update plot" }, { status: 500 })
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    await prisma.plot.delete({ where: { id } })
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("Error deleting plot:", error)
    return NextResponse.json({ error: "Failed to delete plot" }, { status: 500 })
  }
}
NOVAPRATA_EOF
echo "==> src/app/api/plots/[id]/route.ts escrito"

mkdir -p "src/app/api/harvest-lots/[id]"
cat > "src/app/api/harvest-lots/[id]/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    const body = await request.json()
    const { blockNumber, plot, harvestDate, classification, bales, totalWeightKg, status, invoiceNumber, notes } = body

    const lot = await prisma.harvestLot.update({
      where: { id },
      data: {
        blockNumber: blockNumber || null,
        plot: plot || null,
        harvestDate: harvestDate ? new Date(harvestDate) : null,
        classification: classification || null,
        bales: Number(bales) || 0,
        totalWeightKg: Number(totalWeightKg) || 0,
        status: status || "colhido",
        invoiceNumber: invoiceNumber || null,
        notes: notes || null,
      },
    })

    return NextResponse.json(lot)
  } catch (error) {
    console.error("Error updating harvest lot:", error)
    return NextResponse.json({ error: "Failed to update harvest lot" }, { status: 500 })
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    await prisma.harvestLot.delete({ where: { id } })
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("Error deleting harvest lot:", error)
    return NextResponse.json({ error: "Failed to delete harvest lot" }, { status: 500 })
  }
}
NOVAPRATA_EOF
echo "==> src/app/api/harvest-lots/[id]/route.ts escrito"

mkdir -p "src/app/(dashboard)/producers"
cat > "src/app/(dashboard)/producers/page.tsx" << 'NOVAPRATA_EOF'
"use client"

import React from "react"
import Link from "next/link"
import { Search, UserPlus, Loader2, RefreshCcw, MapPin, LayoutGrid, Package, ArrowUpRight, Download } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { AnimatedCounter } from "@/components/ui/animated-counter"
import { AuroraGlow } from "@/components/aurora-glow"
import { cn } from "@/lib/utils"
import { useConfirm } from "@/components/confirm-dialog-provider"
import { useToast } from "@/components/toast-provider"
import { ProducerForm } from "@/components/features/producers/ProducerForm"

function initials(name: string) {
  return name.split(" ").filter(Boolean).slice(0, 2).map(p => p[0]).join("").toUpperCase()
}

function statusVariant(status: string) {
  if (status === "ativo") return "success"
  if (status === "pendente") return "warning"
  return "outline"
}

export default function ProducersPage() {
  const confirmDialog = useConfirm()
  const { success, error: toastError } = useToast()
  const [producers, setProducers] = React.useState<any[]>([])
  const [loading, setLoading] = React.useState(true)
  const [searchTerm, setSearchTerm] = React.useState("")
  const [statusFilter, setStatusFilter] = React.useState("todos")
  const [exporting, setExporting] = React.useState(false)
  const [isModalOpen, setIsModalOpen] = React.useState(false)
  const [editingProducer, setEditingProducer] = React.useState<any>(null)
  const [error, setError] = React.useState<string | null>(null)

  const fetchProducers = React.useCallback(async () => {
    setLoading(true)
    try {
      const res = await fetch("/api/producers")
      const data = await res.json()
      if (Array.isArray(data)) setProducers(data)
    } catch (error) {
      console.error("Error fetching producers:", error)
    } finally {
      setLoading(false)
    }
  }, [])

  React.useEffect(() => { fetchProducers() }, [fetchProducers])

  async function handleCreateOrUpdate(data: any) {
    setError(null)
    const url = editingProducer ? `/api/producers/${editingProducer.id}` : "/api/producers"
    const method = editingProducer ? "PUT" : "POST"
    try {
      const res = await fetch(url, {
        method,
        body: JSON.stringify(data),
        headers: { "Content-Type": "application/json" },
      })
      const result = await res.json()
      if (res.ok) {
        setIsModalOpen(false)
        setEditingProducer(null)
        success(editingProducer ? "Produtor atualizado" : "Produtor criado")
        fetchProducers()
      } else {
        setError(result.error || "Erro ao salvar produtor")
      }
    } catch (err) {
      console.error("Error saving producer:", err)
      setError("Erro ao salvar produtor")
    }
  }

  async function handleDelete(id: string, e: React.MouseEvent) {
    e.preventDefault()
    e.stopPropagation()
    const ok = await confirmDialog({ title: "Excluir produtor", message: "Deseja realmente excluir este produtor?", destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/producers/${id}`, { method: "DELETE" })
      const result = await res.json()
      if (res.ok) {
        success("Produtor excluído")
        fetchProducers()
      } else {
        toastError(result.error || "Erro ao excluir produtor")
      }
    } catch (error) {
      console.error("Error deleting producer:", error)
      toastError("Erro ao excluir produtor")
    }
  }

  const filtered = producers
    .filter(p => p.name.toLowerCase().includes(searchTerm.toLowerCase()))
    .filter(p => statusFilter === "todos" || p.status === statusFilter)

  async function handleExport() {
    setExporting(true)
    try {
      const res = await fetch("/api/producers/export")
      if (!res.ok) throw new Error("Falha ao exportar")
      const blob = await res.blob()
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement("a")
      a.href = url
      a.download = `produtores-safra-2026-${new Date().toISOString().slice(0, 10)}.xlsx`
      document.body.appendChild(a)
      a.click()
      a.remove()
      window.URL.revokeObjectURL(url)
    } catch (error) {
      console.error("Error exporting:", error)
      toastError("Erro ao exportar produtores")
    } finally {
      setExporting(false)
    }
  }

  const totalArea = producers.reduce(
    (acc, p) => acc + (p.farms || []).reduce((a: number, f: any) => a + (f.plots || []).reduce((x: number, t: any) => x + t.areaHa, 0), 0),
    0
  )
  const totalBales = producers.reduce((acc, p) => acc + (p.harvestLots || []).reduce((a: number, l: any) => a + l.bales, 0), 0)

  if (loading) {
    return (
      <div className="flex h-[80vh] items-center justify-center">
        <Loader2 className="h-10 w-10 animate-spin text-primary" />
      </div>
    )
  }

  return (
    <div className="relative space-y-8 animate-in fade-in duration-500">
      <AuroraGlow />

      <div className="flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
        <div className="flex-1">
          <h1 className="text-3xl sm:text-4xl font-bold tracking-tight" style={{ color: "var(--text-primary)" }}>
            Produtores
          </h1>
          <p className="text-sm mt-2" style={{ color: "var(--text-tertiary)" }}>
            Safra 2026 — fazendas, talhões e colheita por produtor
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={fetchProducers} disabled={loading}>
            <RefreshCcw className={cn("mr-2 h-4 w-4", loading && "animate-spin")} />
            Sincronizar
          </Button>
          <Button variant="outline" size="sm" onClick={handleExport} disabled={exporting}>
            {exporting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Download className="mr-2 h-4 w-4" />}
            Exportar
          </Button>
          <Button
            size="sm"
            className="bg-primary shadow-lg shadow-primary/20"
            onClick={() => { setEditingProducer(null); setError(null); setIsModalOpen(true) }}
          >
            <UserPlus className="mr-2 h-4 w-4" />
            Novo Produtor
          </Button>
        </div>
      </div>

      <div className="grid gap-6 sm:grid-cols-3">
        {[
          { label: "Produtores", value: producers.length, icon: UserPlus, color: "text-blue-500", bg: "bg-blue-500/10" },
          { label: "Área plantada", value: totalArea, suffix: " ha", icon: MapPin, color: "text-emerald-500", bg: "bg-emerald-500/10" },
          { label: "Fardos colhidos", value: totalBales, icon: Package, color: "text-violet-500", bg: "bg-violet-500/10" },
        ].map((s) => (
          <Card key={s.label}>
            <CardContent className="p-5 sm:p-6 flex items-center justify-between">
              <div>
                <p className="text-xs sm:text-sm font-semibold" style={{ color: "var(--text-tertiary)" }}>{s.label}</p>
                <div className="text-3xl font-bold mt-2" style={{ letterSpacing: "-0.03em", color: "var(--text-primary)" }}>
                  <AnimatedCounter value={s.value} />{s.suffix || ""}
                </div>
              </div>
              <div className={cn("p-3 rounded-xl flex-shrink-0", s.bg)}>
                <s.icon className={cn("h-5 w-5", s.color)} />
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4" style={{ color: "var(--text-tertiary)" }} />
          <Input
            placeholder="Buscar por nome..."
            className="pl-10 h-11"
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
          />
        </div>
        <select
          className="h-11 rounded-lg border border-zinc-700/50 bg-background px-3 text-sm sm:w-48"
          value={statusFilter}
          onChange={e => setStatusFilter(e.target.value)}
        >
          <option value="todos">Todos os status</option>
          <option value="ativo">Ativo</option>
          <option value="pendente">Pendente</option>
          <option value="inativo">Inativo</option>
        </select>
      </div>

      {filtered.length === 0 ? (
        <Card>
          <CardContent className="p-12 text-center" style={{ color: "var(--text-tertiary)" }}>
            Nenhum produtor encontrado.
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {filtered.map((p) => {
            const areaTotal = (p.farms || []).reduce(
              (acc: number, f: any) => acc + (f.plots || []).reduce((a: number, t: any) => a + t.areaHa, 0),
              0
            )
            const totalPlots = (p.farms || []).reduce((acc: number, f: any) => acc + (f.plots || []).length, 0)
            const bales = (p.harvestLots || []).reduce((acc: number, l: any) => acc + l.bales, 0)

            return (
              <Link key={p.id} href={`/producers/${p.id}`} className="group block">
                <Card className="cursor-pointer hover:border-blue-200 hover:shadow-lg transition-all duration-200">
                  <CardContent className="p-5 sm:p-6">
                    <div className="flex items-center justify-between gap-3 mb-5">
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="h-11 w-11 rounded-xl bg-primary/10 flex items-center justify-center text-primary font-bold shrink-0">
                          {initials(p.name)}
                        </div>
                        <p className="font-semibold leading-tight truncate" style={{ color: "var(--text-primary)" }}>{p.name}</p>
                      </div>
                      <ArrowUpRight className="h-4 w-4 text-primary opacity-0 transition-opacity group-hover:opacity-100 flex-shrink-0" />
                    </div>

                    <div className="flex items-center justify-between mb-4">
                      <Badge variant={statusVariant(p.status)}>{p.status}</Badge>
                    </div>

                    <div className="grid grid-cols-3 gap-2 text-center pt-4" style={{ borderTop: "1px solid var(--border)" }}>
                      <div>
                        <p className="text-xs flex items-center justify-center gap-1" style={{ color: "var(--text-tertiary)" }}><MapPin className="h-3 w-3" />Área</p>
                        <p className="font-semibold mt-1" style={{ color: "var(--text-primary)" }}>{areaTotal || "-"}{areaTotal ? " ha" : ""}</p>
                      </div>
                      <div>
                        <p className="text-xs flex items-center justify-center gap-1" style={{ color: "var(--text-tertiary)" }}><LayoutGrid className="h-3 w-3" />Talhões</p>
                        <p className="font-semibold mt-1" style={{ color: "var(--text-primary)" }}>{totalPlots || "-"}</p>
                      </div>
                      <div>
                        <p className="text-xs flex items-center justify-center gap-1" style={{ color: "var(--text-tertiary)" }}><Package className="h-3 w-3" />Fardos</p>
                        <p className="font-semibold mt-1" style={{ color: "var(--text-primary)" }}>{bales || "-"}</p>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </Link>
            )
          })}
        </div>
      )}

      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingProducer ? "Editar Produtor" : "Novo Produtor"}
      >
        {error && (
          <div className="mb-4 p-3 rounded-md bg-red-500/10 border border-red-500/20 text-sm text-red-500">
            {error}
          </div>
        )}
        <ProducerForm
          initialData={editingProducer}
          onCancel={() => setIsModalOpen(false)}
          onSubmit={handleCreateOrUpdate}
        />
      </Modal>
    </div>
  )
}
NOVAPRATA_EOF
echo "==> src/app/(dashboard)/producers/page.tsx escrito"

mkdir -p "src/app/(dashboard)/producers/[id]"
cat > "src/app/(dashboard)/producers/[id]/page.tsx" << 'NOVAPRATA_EOF'
"use client"

import React from "react"
import { useParams, useRouter } from "next/navigation"
import {
  ArrowLeft, Loader2, Phone, Mail, MessageCircle, MapPin, Building2, LayoutGrid, Package,
  Edit, Trash2, Plus, Upload, Download, FileText,
} from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { AnimatedCounter } from "@/components/ui/animated-counter"
import { AuroraGlow } from "@/components/aurora-glow"
import { cn } from "@/lib/utils"
import { useConfirm } from "@/components/confirm-dialog-provider"
import { useToast } from "@/components/toast-provider"
import { ProducerForm } from "@/components/features/producers/ProducerForm"
import { FarmForm, PlotForm, HarvestLotForm } from "@/components/features/producers/FarmPlotHarvestForms"

const TABS = ["Dados gerais", "Fazendas e talhões", "Safras", "Colheita e lotes", "Documentos"] as const

function initials(name: string) {
  return name.split(" ").filter(Boolean).slice(0, 2).map(p => p[0]).join("").toUpperCase()
}

function statusVariant(status: string) {
  if (status === "ativo") return "success"
  if (status === "pendente") return "warning"
  return "outline"
}

export default function ProducerDetailPage() {
  const params = useParams<{ id: string }>()
  const router = useRouter()
  const confirmDialog = useConfirm()
  const { success, error: toastError } = useToast()

  const [producer, setProducer] = React.useState<any>(null)
  const [loading, setLoading] = React.useState(true)
  const [tab, setTab] = React.useState<(typeof TABS)[number]>("Fazendas e talhões")

  const [editProducerOpen, setEditProducerOpen] = React.useState(false)
  const [farmModal, setFarmModal] = React.useState<{ open: boolean; editing: any | null }>({ open: false, editing: null })
  const [plotModal, setPlotModal] = React.useState<{ open: boolean; editing: any | null; farmId: string | null }>({ open: false, editing: null, farmId: null })
  const [lotModal, setLotModal] = React.useState<{ open: boolean; editing: any | null }>({ open: false, editing: null })
  const [uploadingDoc, setUploadingDoc] = React.useState(false)

  const fetchProducer = React.useCallback(async () => {
    try {
      const res = await fetch(`/api/producers/${params.id}`)
      if (res.ok) setProducer(await res.json())
    } catch (error) {
      console.error("Error fetching producer:", error)
    } finally {
      setLoading(false)
    }
  }, [params.id])

  React.useEffect(() => { if (params.id) fetchProducer() }, [params.id, fetchProducer])

  async function handleEditProducer(data: any) {
    try {
      const res = await fetch(`/api/producers/${params.id}`, {
        method: "PUT",
        body: JSON.stringify(data),
        headers: { "Content-Type": "application/json" },
      })
      if (res.ok) {
        setEditProducerOpen(false)
        success("Produtor atualizado")
        fetchProducer()
      } else {
        toastError("Erro ao atualizar produtor")
      }
    } catch (error) {
      console.error(error)
      toastError("Erro ao atualizar produtor")
    }
  }

  async function handleDeleteProducer() {
    const ok = await confirmDialog({ title: "Excluir produtor", message: `Deseja realmente excluir ${producer.name}? Isso apaga fazendas, talhões e lotes vinculados.`, destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/producers/${params.id}`, { method: "DELETE" })
      if (res.ok) {
        success("Produtor excluído")
        router.push("/producers")
      } else {
        toastError("Erro ao excluir produtor")
      }
    } catch (error) {
      console.error(error)
      toastError("Erro ao excluir produtor")
    }
  }

  async function handleFarmSubmit(data: any) {
    try {
      const url = farmModal.editing ? `/api/farms/${farmModal.editing.id}` : `/api/producers/${params.id}/farms`
      const method = farmModal.editing ? "PUT" : "POST"
      const res = await fetch(url, { method, body: JSON.stringify(data), headers: { "Content-Type": "application/json" } })
      if (res.ok) {
        success(farmModal.editing ? "Fazenda atualizada" : "Fazenda criada")
        setFarmModal({ open: false, editing: null })
        fetchProducer()
      } else {
        toastError("Erro ao salvar fazenda")
      }
    } catch (error) {
      console.error(error)
      toastError("Erro ao salvar fazenda")
    }
  }

  async function handleDeleteFarm(farm: any) {
    const ok = await confirmDialog({ title: "Excluir fazenda", message: `Excluir "${farm.name}" e todos os talhões dela?`, destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/farms/${farm.id}`, { method: "DELETE" })
      if (res.ok) { success("Fazenda excluída"); fetchProducer() } else { toastError("Erro ao excluir fazenda") }
    } catch (error) {
      console.error(error)
      toastError("Erro ao excluir fazenda")
    }
  }

  async function handlePlotSubmit(data: any) {
    try {
      const url = plotModal.editing ? `/api/plots/${plotModal.editing.id}` : `/api/farms/${plotModal.farmId}/plots`
      const method = plotModal.editing ? "PUT" : "POST"
      const res = await fetch(url, { method, body: JSON.stringify(data), headers: { "Content-Type": "application/json" } })
      if (res.ok) {
        success(plotModal.editing ? "Talhão atualizado" : "Talhão criado")
        setPlotModal({ open: false, editing: null, farmId: null })
        fetchProducer()
      } else {
        toastError("Erro ao salvar talhão")
      }
    } catch (error) {
      console.error(error)
      toastError("Erro ao salvar talhão")
    }
  }

  async function handleDeletePlot(plot: any) {
    const ok = await confirmDialog({ title: "Excluir talhão", message: `Excluir o talhão "${plot.name}"?`, destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/plots/${plot.id}`, { method: "DELETE" })
      if (res.ok) { success("Talhão excluído"); fetchProducer() } else { toastError("Erro ao excluir talhão") }
    } catch (error) {
      console.error(error)
      toastError("Erro ao excluir talhão")
    }
  }

  async function handleLotSubmit(data: any) {
    try {
      const url = lotModal.editing ? `/api/harvest-lots/${lotModal.editing.id}` : `/api/producers/${params.id}/harvest-lots`
      const method = lotModal.editing ? "PUT" : "POST"
      const res = await fetch(url, { method, body: JSON.stringify(data), headers: { "Content-Type": "application/json" } })
      if (res.ok) {
        success(lotModal.editing ? "Lote atualizado" : "Lote lançado")
        setLotModal({ open: false, editing: null })
        fetchProducer()
      } else {
        toastError("Erro ao salvar lote")
      }
    } catch (error) {
      console.error(error)
      toastError("Erro ao salvar lote")
    }
  }

  async function handleDeleteLot(lot: any) {
    const ok = await confirmDialog({ title: "Excluir lote", message: `Excluir o lote "${lot.blockNumber || lot.id}"?`, destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/harvest-lots/${lot.id}`, { method: "DELETE" })
      if (res.ok) { success("Lote excluído"); fetchProducer() } else { toastError("Erro ao excluir lote") }
    } catch (error) {
      console.error(error)
      toastError("Erro ao excluir lote")
    }
  }

  async function handleFileUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    e.target.value = ""

    if (file.size > 4 * 1024 * 1024) {
      toastError("Arquivo maior que 4MB não é suportado")
      return
    }

    setUploadingDoc(true)
    try {
      const fileData = await new Promise<string>((resolve, reject) => {
        const reader = new FileReader()
        reader.onload = () => resolve(String(reader.result).split(",")[1])
        reader.onerror = reject
        reader.readAsDataURL(file)
      })

      const res = await fetch(`/api/producers/${params.id}/documents`, {
        method: "POST",
        body: JSON.stringify({ fileName: file.name, mimeType: file.type || "application/octet-stream", fileData }),
        headers: { "Content-Type": "application/json" },
      })

      if (res.ok) {
        success("Documento enviado")
        fetchProducer()
      } else {
        const result = await res.json().catch(() => null)
        toastError(result?.error || "Erro ao enviar documento")
      }
    } catch (error) {
      console.error(error)
      toastError("Erro ao enviar documento")
    } finally {
      setUploadingDoc(false)
    }
  }

  async function handleDeleteDocument(doc: any) {
    const ok = await confirmDialog({ title: "Excluir documento", message: `Excluir "${doc.fileName}"?`, destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/producer-documents/${doc.id}`, { method: "DELETE" })
      if (res.ok) { success("Documento excluído"); fetchProducer() } else { toastError("Erro ao excluir documento") }
    } catch (error) {
      console.error(error)
      toastError("Erro ao excluir documento")
    }
  }

  if (loading) {
    return (
      <div className="flex h-[80vh] items-center justify-center">
        <Loader2 className="h-10 w-10 animate-spin text-primary" />
      </div>
    )
  }

  if (!producer) {
    return (
      <div className="p-12 text-center" style={{ color: "var(--text-tertiary)" }}>
        Produtor não encontrado.
      </div>
    )
  }

  const areaTotal = (producer.farms || []).reduce(
    (acc: number, f: any) => acc + (f.plots || []).reduce((a: number, t: any) => a + t.areaHa, 0),
    0
  )
  const totalPlots = (producer.farms || []).reduce((acc: number, f: any) => acc + (f.plots || []).length, 0)
  const bales = (producer.harvestLots || []).reduce((acc: number, l: any) => acc + l.bales, 0)

  const stats = [
    { label: "Área total", value: areaTotal, suffix: " ha", icon: MapPin, color: "text-emerald-500", bg: "bg-emerald-500/10" },
    { label: "Fazendas", value: producer.farms?.length || 0, icon: Building2, color: "text-blue-500", bg: "bg-blue-500/10" },
    { label: "Talhões", value: totalPlots, icon: LayoutGrid, color: "text-amber-500", bg: "bg-amber-500/10" },
    { label: "Fardos colhidos", value: bales, icon: Package, color: "text-violet-500", bg: "bg-violet-500/10" },
  ]

  return (
    <div className="relative space-y-6 animate-in fade-in duration-500 max-w-4xl">
      <AuroraGlow />

      <div className="flex items-center justify-between">
        <Button variant="ghost" size="sm" onClick={() => router.push("/producers")}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Voltar
        </Button>
        <div className="flex gap-2">
          <Button onClick={() => setEditProducerOpen(true)} size="sm">
            <Edit className="mr-2 h-4 w-4" />
            Editar
          </Button>
          <Button onClick={handleDeleteProducer} variant="outline" size="sm" style={{ color: "var(--status-error)" }}>
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      </div>

      <Card>
        <CardContent className="p-5 sm:p-6 flex items-center justify-between flex-wrap gap-4">
          <div className="flex items-center gap-4">
            <div className="h-16 w-16 rounded-2xl bg-primary/10 flex items-center justify-center text-primary font-bold text-xl">
              {initials(producer.name)}
            </div>
            <div>
              <p className="font-bold text-xl leading-tight" style={{ color: "var(--text-primary)" }}>{producer.name}</p>
              <p className="text-sm mt-1" style={{ color: "var(--text-tertiary)" }}>Safra atual: 2026</p>
            </div>
          </div>
          <Badge variant={statusVariant(producer.status)}>{producer.status}</Badge>
        </CardContent>
      </Card>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {stats.map((s) => (
          <Card key={s.label}>
            <CardContent className="p-4 sm:p-5">
              <div className={cn("h-9 w-9 rounded-lg flex items-center justify-center mb-3", s.bg)}>
                <s.icon className={cn("h-4 w-4", s.color)} />
              </div>
              <p className="text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>{s.label}</p>
              <div className="text-2xl font-bold mt-1" style={{ letterSpacing: "-0.02em", color: "var(--text-primary)" }}>
                <AnimatedCounter value={s.value} />{s.suffix || ""}
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="flex gap-1 overflow-x-auto" style={{ borderBottom: "1px solid var(--border)" }}>
        {TABS.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className="px-3 py-2.5 text-sm whitespace-nowrap transition-colors duration-200 font-medium"
            style={
              tab === t
                ? { color: "var(--primary)", borderBottom: "2px solid var(--primary)" }
                : { color: "var(--text-tertiary)" }
            }
          >
            {t}
          </button>
        ))}
      </div>

      {tab === "Dados gerais" && (
        <Card>
          <CardContent className="p-5 sm:p-6 space-y-5 text-sm">
            <div className="grid grid-cols-2 gap-5">
              <div>
                <p className="text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>CPF/CNPJ</p>
                <p className="mt-1" style={{ color: "var(--text-primary)" }}>{producer.document || "-"}</p>
              </div>
              <div>
                <p className="text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Inscrição Estadual</p>
                <p className="mt-1" style={{ color: "var(--text-primary)" }}>{producer.stateRegistration || "-"}</p>
              </div>
            </div>
            <div>
              <p className="text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Endereço</p>
              <p className="mt-1" style={{ color: "var(--text-primary)" }}>{producer.address || "-"}</p>
            </div>
            <div className="pt-4 space-y-3" style={{ borderTop: "1px solid var(--border)" }}>
              <p className="flex items-center gap-2"><Phone className="h-4 w-4" style={{ color: "var(--text-tertiary)" }} />{producer.phone || "-"}</p>
              <p className="flex items-center gap-2"><Mail className="h-4 w-4" style={{ color: "var(--text-tertiary)" }} />{producer.email || "-"}</p>
              <p className="flex items-center gap-2"><MessageCircle className="h-4 w-4" style={{ color: "var(--text-tertiary)" }} />{producer.whatsapp || "-"}</p>
            </div>
            <p className="pt-4" style={{ borderTop: "1px solid var(--border)", color: "var(--text-tertiary)" }}>
              {producer.notes || "Sem observações."}
            </p>
          </CardContent>
        </Card>
      )}

      {tab === "Fazendas e talhões" && (
        <div className="space-y-4">
          <div className="flex justify-end">
            <Button size="sm" onClick={() => setFarmModal({ open: true, editing: null })}>
              <Plus className="mr-2 h-4 w-4" />
              Nova fazenda
            </Button>
          </div>

          {(!producer.farms || producer.farms.length === 0) && (
            <Card><CardContent className="p-6 text-sm" style={{ color: "var(--text-tertiary)" }}>Nenhuma fazenda cadastrada ainda.</CardContent></Card>
          )}

          {(producer.farms || []).map((f: any) => (
            <Card key={f.id}>
              <CardContent className="p-5 sm:p-6">
                <div className="flex items-center justify-between mb-4">
                  <p className="font-semibold text-sm flex items-center gap-2" style={{ color: "var(--text-primary)" }}>
                    <MapPin className="h-4 w-4 text-emerald-500" />{f.name}
                  </p>
                  <div className="flex gap-1">
                    <Button size="sm" variant="ghost" onClick={() => setPlotModal({ open: true, editing: null, farmId: f.id })}>
                      <Plus className="mr-1 h-3.5 w-3.5" />
                      Talhão
                    </Button>
                    <Button size="icon" variant="ghost" className="h-8 w-8" onClick={() => setFarmModal({ open: true, editing: f })}>
                      <Edit className="h-3.5 w-3.5" />
                    </Button>
                    <Button size="icon" variant="ghost" className="h-8 w-8" style={{ color: "var(--status-error)" }} onClick={() => handleDeleteFarm(f)}>
                      <Trash2 className="h-3.5 w-3.5" />
                    </Button>
                  </div>
                </div>
                <table className="w-full text-sm">
                  <thead>
                    <tr style={{ borderBottom: "1px solid var(--border)" }}>
                      <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Talhão</th>
                      <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Área</th>
                      <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Variedade</th>
                      <th className="pb-2.5 text-right text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}></th>
                    </tr>
                  </thead>
                  <tbody>
                    {f.plots.map((t: any) => (
                      <tr key={t.id} className="group transition-colors duration-200 hover:bg-zinc-500/5" style={{ borderBottom: "1px solid var(--border)" }}>
                        <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{t.name}</td>
                        <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{t.areaHa} ha</td>
                        <td className="py-2.5" style={{ color: "var(--text-primary)" }}>
                          {t.variety}
                          {t.splitArea && <span className="ml-2 text-xs" style={{ color: "var(--text-tertiary)" }}>(área dividida)</span>}
                        </td>
                        <td className="py-2.5 text-right">
                          <div className="flex justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                            <Button size="icon" variant="ghost" className="h-7 w-7" onClick={() => setPlotModal({ open: true, editing: t, farmId: f.id })}>
                              <Edit className="h-3.5 w-3.5" />
                            </Button>
                            <Button size="icon" variant="ghost" className="h-7 w-7" style={{ color: "var(--status-error)" }} onClick={() => handleDeletePlot(t)}>
                              <Trash2 className="h-3.5 w-3.5" />
                            </Button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {tab === "Safras" && (
        <Card><CardContent className="p-5 sm:p-6 text-sm" style={{ color: "var(--text-tertiary)" }}>Histórico multi-safra entra aqui quando tivermos mais de um ano cadastrado.</CardContent></Card>
      )}

      {tab === "Colheita e lotes" && (
        <Card>
          <CardContent className="p-5 sm:p-6">
            <div className="flex justify-end mb-4">
              <Button size="sm" onClick={() => setLotModal({ open: true, editing: null })}>
                <Plus className="mr-2 h-4 w-4" />
                Novo lote
              </Button>
            </div>
            {(!producer.harvestLots || producer.harvestLots.length === 0) ? (
              <p className="text-sm" style={{ color: "var(--text-tertiary)" }}>Nenhum lote lançado ainda.</p>
            ) : (
              <table className="w-full text-sm">
                <thead>
                  <tr style={{ borderBottom: "1px solid var(--border)" }}>
                    <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Bloco</th>
                    <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Talhão</th>
                    <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Fardos</th>
                    <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Peso (kg)</th>
                    <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Status</th>
                    <th className="pb-2.5 text-right text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}></th>
                  </tr>
                </thead>
                <tbody>
                  {producer.harvestLots.map((l: any) => (
                    <tr key={l.id} className="group transition-colors duration-200 hover:bg-zinc-500/5" style={{ borderBottom: "1px solid var(--border)" }}>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{l.blockNumber || "-"}</td>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{l.plot || "-"}</td>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{l.bales}</td>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{l.totalWeightKg}</td>
                      <td className="py-2.5"><Badge variant="ghost">{l.status}</Badge></td>
                      <td className="py-2.5 text-right">
                        <div className="flex justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                          <Button size="icon" variant="ghost" className="h-7 w-7" onClick={() => setLotModal({ open: true, editing: l })}>
                            <Edit className="h-3.5 w-3.5" />
                          </Button>
                          <Button size="icon" variant="ghost" className="h-7 w-7" style={{ color: "var(--status-error)" }} onClick={() => handleDeleteLot(l)}>
                            <Trash2 className="h-3.5 w-3.5" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </CardContent>
        </Card>
      )}

      {tab === "Documentos" && (
        <Card>
          <CardContent className="p-5 sm:p-6 space-y-4">
            <div className="flex items-center justify-between">
              <p className="text-sm" style={{ color: "var(--text-tertiary)" }}>
                Contratos, CAR, procurações e outros anexos. Máximo 4MB por arquivo.
              </p>
              <label>
                <input
                  type="file"
                  className="hidden"
                  onChange={handleFileUpload}
                  disabled={uploadingDoc}
                />
                <Button size="sm" asChild disabled={uploadingDoc}>
                  <span>
                    {uploadingDoc ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Upload className="mr-2 h-4 w-4" />}
                    Enviar arquivo
                  </span>
                </Button>
              </label>
            </div>

            {(!producer.documents || producer.documents.length === 0) ? (
              <p className="text-sm" style={{ color: "var(--text-tertiary)" }}>Nenhum documento enviado ainda.</p>
            ) : (
              <table className="w-full text-sm">
                <thead>
                  <tr style={{ borderBottom: "1px solid var(--border)" }}>
                    <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Arquivo</th>
                    <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Tamanho</th>
                    <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Enviado em</th>
                    <th className="pb-2.5 text-right text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}></th>
                  </tr>
                </thead>
                <tbody>
                  {producer.documents.map((d: any) => (
                    <tr key={d.id} className="group transition-colors duration-200 hover:bg-zinc-500/5" style={{ borderBottom: "1px solid var(--border)" }}>
                      <td className="py-2.5 flex items-center gap-2" style={{ color: "var(--text-primary)" }}>
                        <FileText className="h-4 w-4" style={{ color: "var(--text-tertiary)" }} />
                        {d.fileName}
                      </td>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{(d.fileSize / 1024).toFixed(0)} KB</td>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{new Date(d.uploadedAt).toLocaleDateString("pt-BR")}</td>
                      <td className="py-2.5 text-right">
                        <div className="flex justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                          <Button size="icon" variant="ghost" className="h-7 w-7" onClick={() => window.open(`/api/producer-documents/${d.id}`, "_blank")} aria-label={`Baixar ${d.fileName}`}>
                            <Download className="h-3.5 w-3.5" />
                          </Button>
                          <Button size="icon" variant="ghost" className="h-7 w-7" style={{ color: "var(--status-error)" }} onClick={() => handleDeleteDocument(d)} aria-label={`Excluir ${d.fileName}`}>
                            <Trash2 className="h-3.5 w-3.5" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </CardContent>
        </Card>
      )}

      <Modal isOpen={editProducerOpen} onClose={() => setEditProducerOpen(false)} title="Editar Produtor">
        <ProducerForm initialData={producer} onCancel={() => setEditProducerOpen(false)} onSubmit={handleEditProducer} />
      </Modal>

      <Modal isOpen={farmModal.open} onClose={() => setFarmModal({ open: false, editing: null })} title={farmModal.editing ? "Editar Fazenda" : "Nova Fazenda"}>
        <FarmForm initialData={farmModal.editing} onCancel={() => setFarmModal({ open: false, editing: null })} onSubmit={handleFarmSubmit} />
      </Modal>

      <Modal isOpen={plotModal.open} onClose={() => setPlotModal({ open: false, editing: null, farmId: null })} title={plotModal.editing ? "Editar Talhão" : "Novo Talhão"}>
        <PlotForm initialData={plotModal.editing} onCancel={() => setPlotModal({ open: false, editing: null, farmId: null })} onSubmit={handlePlotSubmit} />
      </Modal>

      <Modal isOpen={lotModal.open} onClose={() => setLotModal({ open: false, editing: null })} title={lotModal.editing ? "Editar Lote" : "Novo Lote de Colheita"}>
        <HarvestLotForm initialData={lotModal.editing} onCancel={() => setLotModal({ open: false, editing: null })} onSubmit={handleLotSubmit} />
      </Modal>
    </div>
  )
}
NOVAPRATA_EOF
echo "==> src/app/(dashboard)/producers/[id]/page.tsx escrito"

mkdir -p "src/components/features/producers"
cat > "src/components/features/producers/ProducerForm.tsx" << 'NOVAPRATA_EOF'
"use client"

import * as React from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Loader2 } from "lucide-react"

interface ProducerFormProps {
  initialData?: any
  onSubmit: (data: any) => Promise<void>
  onCancel: () => void
}

export function ProducerForm({ initialData, onSubmit, onCancel }: ProducerFormProps) {
  const [loading, setLoading] = React.useState(false)
  const [formData, setFormData] = React.useState({
    name: initialData?.name || "",
    document: initialData?.document || "",
    stateRegistration: initialData?.stateRegistration || "",
    address: initialData?.address || "",
    phone: initialData?.phone || "",
    email: initialData?.email || "",
    whatsapp: initialData?.whatsapp || "",
    status: initialData?.status || "ativo",
    notes: initialData?.notes || "",
  })

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    try {
      await onSubmit(formData)
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Nome</label>
          <Input required value={formData.name} onChange={e => setFormData({ ...formData, name: e.target.value })} />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">CPF/CNPJ</label>
          <Input value={formData.document} onChange={e => setFormData({ ...formData, document: e.target.value })} />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Inscrição Estadual</label>
          <Input value={formData.stateRegistration} onChange={e => setFormData({ ...formData, stateRegistration: e.target.value })} />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Endereço</label>
          <Input value={formData.address} onChange={e => setFormData({ ...formData, address: e.target.value })} />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Telefone</label>
          <Input value={formData.phone} onChange={e => setFormData({ ...formData, phone: e.target.value })} />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">WhatsApp</label>
          <Input value={formData.whatsapp} onChange={e => setFormData({ ...formData, whatsapp: e.target.value })} />
        </div>
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium">E-mail</label>
        <Input type="email" value={formData.email} onChange={e => setFormData({ ...formData, email: e.target.value })} />
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium">Status</label>
        <select
          className="flex h-9 w-full rounded-lg border border-zinc-700/50 bg-background px-3 py-2 text-sm"
          value={formData.status}
          onChange={e => setFormData({ ...formData, status: e.target.value })}
        >
          <option value="ativo">Ativo</option>
          <option value="pendente">Pendente</option>
          <option value="inativo">Inativo</option>
        </select>
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium">Observações</label>
        <textarea
          className="flex w-full rounded-lg border border-zinc-700/50 bg-background px-3 py-2 text-sm min-h-[80px]"
          value={formData.notes}
          onChange={e => setFormData({ ...formData, notes: e.target.value })}
        />
      </div>

      <div className="flex justify-end gap-3 pt-2 border-t border-zinc-800/50">
        <Button type="button" variant="ghost" onClick={onCancel}>Cancelar</Button>
        <Button type="submit" disabled={loading}>
          {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
          Salvar
        </Button>
      </div>
    </form>
  )
}
NOVAPRATA_EOF
echo "==> src/components/features/producers/ProducerForm.tsx escrito"

mkdir -p "src/components/features/producers"
cat > "src/components/features/producers/FarmPlotHarvestForms.tsx" << 'NOVAPRATA_EOF'
"use client"

import * as React from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Loader2 } from "lucide-react"

export function FarmForm({ initialData, onSubmit, onCancel }: { initialData?: any; onSubmit: (d: any) => Promise<void>; onCancel: () => void }) {
  const [loading, setLoading] = React.useState(false)
  const [name, setName] = React.useState(initialData?.name || "")

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    try {
      await onSubmit({ name })
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="space-y-2">
        <label className="text-sm font-medium">Nome da fazenda</label>
        <Input required value={name} onChange={e => setName(e.target.value)} placeholder="Ex: Fazenda Boa Vista" />
      </div>
      <div className="flex justify-end gap-3 pt-2 border-t border-zinc-800/50">
        <Button type="button" variant="ghost" onClick={onCancel}>Cancelar</Button>
        <Button type="submit" disabled={loading}>
          {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
          Salvar
        </Button>
      </div>
    </form>
  )
}

export function PlotForm({ initialData, onSubmit, onCancel }: { initialData?: any; onSubmit: (d: any) => Promise<void>; onCancel: () => void }) {
  const [loading, setLoading] = React.useState(false)
  const [formData, setFormData] = React.useState({
    name: initialData?.name || "",
    areaHa: initialData?.areaHa || "",
    variety: initialData?.variety || "",
    splitArea: initialData?.splitArea || false,
    season: initialData?.season || "2026",
    notes: initialData?.notes || "",
  })

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    try {
      await onSubmit(formData)
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Talhão</label>
          <Input required value={formData.name} onChange={e => setFormData({ ...formData, name: e.target.value })} placeholder="Ex: 01 e 02" />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Área (ha)</label>
          <Input required type="number" step="0.01" value={formData.areaHa} onChange={e => setFormData({ ...formData, areaHa: e.target.value })} />
        </div>
      </div>
      <div className="space-y-2">
        <label className="text-sm font-medium">Variedade</label>
        <Input required value={formData.variety} onChange={e => setFormData({ ...formData, variety: e.target.value })} placeholder="Ex: FB 911" />
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Safra</label>
          <Input value={formData.season} onChange={e => setFormData({ ...formData, season: e.target.value })} />
        </div>
        <div className="flex items-end pb-2">
          <label className="text-sm font-medium flex items-center gap-2">
            <input type="checkbox" checked={formData.splitArea} onChange={e => setFormData({ ...formData, splitArea: e.target.checked })} />
            Área dividida entre variedades
          </label>
        </div>
      </div>
      <div className="space-y-2">
        <label className="text-sm font-medium">Observações</label>
        <textarea
          className="flex w-full rounded-lg border border-zinc-700/50 bg-background px-3 py-2 text-sm min-h-[60px]"
          value={formData.notes}
          onChange={e => setFormData({ ...formData, notes: e.target.value })}
        />
      </div>
      <div className="flex justify-end gap-3 pt-2 border-t border-zinc-800/50">
        <Button type="button" variant="ghost" onClick={onCancel}>Cancelar</Button>
        <Button type="submit" disabled={loading}>
          {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
          Salvar
        </Button>
      </div>
    </form>
  )
}

export function HarvestLotForm({ initialData, onSubmit, onCancel }: { initialData?: any; onSubmit: (d: any) => Promise<void>; onCancel: () => void }) {
  const [loading, setLoading] = React.useState(false)
  const [formData, setFormData] = React.useState({
    blockNumber: initialData?.blockNumber || "",
    plot: initialData?.plot || "",
    harvestDate: initialData?.harvestDate ? String(initialData.harvestDate).slice(0, 10) : "",
    classification: initialData?.classification || "",
    bales: initialData?.bales || "",
    totalWeightKg: initialData?.totalWeightKg || "",
    status: initialData?.status || "colhido",
    invoiceNumber: initialData?.invoiceNumber || "",
    notes: initialData?.notes || "",
  })

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    try {
      await onSubmit(formData)
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Nº do bloco</label>
          <Input value={formData.blockNumber} onChange={e => setFormData({ ...formData, blockNumber: e.target.value })} />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Talhão</label>
          <Input value={formData.plot} onChange={e => setFormData({ ...formData, plot: e.target.value })} />
        </div>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Data da colheita</label>
          <Input type="date" value={formData.harvestDate} onChange={e => setFormData({ ...formData, harvestDate: e.target.value })} />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Classificação</label>
          <Input value={formData.classification} onChange={e => setFormData({ ...formData, classification: e.target.value })} placeholder="Ex: 31.3" />
        </div>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Fardos</label>
          <Input required type="number" value={formData.bales} onChange={e => setFormData({ ...formData, bales: e.target.value })} />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Peso total (kg)</label>
          <Input required type="number" step="0.01" value={formData.totalWeightKg} onChange={e => setFormData({ ...formData, totalWeightKg: e.target.value })} />
        </div>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Status</label>
          <select
            className="flex h-9 w-full rounded-lg border border-zinc-700/50 bg-background px-3 py-2 text-sm"
            value={formData.status}
            onChange={e => setFormData({ ...formData, status: e.target.value })}
          >
            <option value="colhido">Colhido</option>
            <option value="beneficiado">Beneficiado</option>
            <option value="faturado">Faturado</option>
            <option value="cancelado">Cancelado</option>
          </select>
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Nota fiscal</label>
          <Input value={formData.invoiceNumber} onChange={e => setFormData({ ...formData, invoiceNumber: e.target.value })} />
        </div>
      </div>
      <div className="space-y-2">
        <label className="text-sm font-medium">Observações</label>
        <textarea
          className="flex w-full rounded-lg border border-zinc-700/50 bg-background px-3 py-2 text-sm min-h-[60px]"
          value={formData.notes}
          onChange={e => setFormData({ ...formData, notes: e.target.value })}
        />
      </div>
      <div className="flex justify-end gap-3 pt-2 border-t border-zinc-800/50">
        <Button type="button" variant="ghost" onClick={onCancel}>Cancelar</Button>
        <Button type="submit" disabled={loading}>
          {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
          Salvar
        </Button>
      </div>
    </form>
  )
}
NOVAPRATA_EOF
echo "==> src/components/features/producers/FarmPlotHarvestForms.tsx escrito"

mkdir -p "src/components/ui"
cat > "src/components/ui/animated-counter.tsx" << 'NOVAPRATA_EOF'
"use client"

import * as React from "react"
import { animate } from "framer-motion"

export function AnimatedCounter({ value }: { value: number }) {
  const [display, setDisplay] = React.useState(0)
  const prevValue = React.useRef(0)

  React.useEffect(() => {
    const controls = animate(prevValue.current, value, {
      duration: 0.8,
      ease: "easeOut",
      onUpdate: (v) => setDisplay(Math.round(v)),
    })
    prevValue.current = value
    return () => controls.stop()
  }, [value])

  return <>{display}</>
}
NOVAPRATA_EOF
echo "==> src/components/ui/animated-counter.tsx escrito"

# 2) Menu lateral - garante o item Produtores (idempotente)
python3 << 'PYPATCH'
path = "src/app/(dashboard)/layout-client.tsx"
with open(path, encoding='utf-8') as f:
    content = f.read()

changed = False
old_import = 'FileText, Building2 } from "lucide-react"'
new_import = 'FileText, Building2, Sprout } from "lucide-react"'
if old_import in content and 'Sprout' not in content:
    content = content.replace(old_import, new_import)
    changed = True

old_item = '{ icon: Building2, label: "Fornecedores", href: "/suppliers" },'
new_item = old_item + '\n  { icon: Sprout, label: "Produtores", href: "/producers" },'
if old_item in content and '/producers' not in content:
    content = content.replace(old_item, new_item)
    changed = True

if changed:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('==> menu lateral atualizado')
else:
    print('==> menu lateral já tinha Produtores, nada a mudar')
PYPATCH

echo ""
echo "==================================================================="
echo "PRONTO. Novidade dessa vez: upload de documento real na aba"
echo "Documentos (contratos, CAR, procuracoes) - arquivo ate 4MB,"
echo "guardado em base64 no banco, com download e exclusao."
echo ""
echo "Próximos passos:"
echo "1) Rode prisma/manual-sql/producers_module.sql no Neon"
echo "   (agora inclui a tabela producer_documents)"
echo "2) npx prisma generate"
echo "3) npm run dev -> confere /producers"
echo "4) git add . && git commit -m 'feat: upload de documentos por produtor' && git push"
echo "==================================================================="
