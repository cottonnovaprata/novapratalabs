#!/bin/bash
set -e
echo "==> Módulo Produtores - visual premium (safra 2026)"

# 0) Limpeza de tentativas antigas / arquivos soltos de scripts anteriores
rm -rf app/produtores components/produtores 'src/app/(dashboard)/produtores' src/components/features/produtores 2>/dev/null || true
rm -f prisma/manual-sql/2026_produtores.sql prisma/manual-sql/2026_producers.sql prisma/manual-sql/2026_producers_v2_campos.sql 2>/dev/null || true
rm -f prisma/seed-produtores.ts 2>/dev/null || true

# 1) Schema Prisma - idempotente (só mexe se precisar)
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
    content = content.rstrip('\n') + '\n' + '\nmodel Producer {\n  id                String   @id @default(cuid())\n  name              String\n  document          String?\n  stateRegistration String?\n  address           String?\n  phone             String?\n  email             String?\n  whatsapp          String?\n  status            String   @default("ativo")\n  notes             String?\n  createdAt         DateTime @default(now())\n  updatedAt         DateTime @updatedAt\n\n  farms        Farm[]\n  harvestLots  HarvestLot[]\n\n  @@map("producers")\n}\n\nmodel Farm {\n  id          String   @id @default(cuid())\n  name        String\n  producerId  String\n  producer    Producer @relation(fields: [producerId], references: [id], onDelete: Cascade)\n  plots       Plot[]\n  createdAt   DateTime @default(now())\n\n  @@map("farms")\n}\n\nmodel Plot {\n  id           String   @id @default(cuid())\n  name         String\n  areaHa       Float\n  variety      String\n  splitArea    Boolean  @default(false)\n  notes        String?\n  season       String   @default("2026")\n  farmId       String\n  farm         Farm     @relation(fields: [farmId], references: [id], onDelete: Cascade)\n  createdAt    DateTime @default(now())\n\n  @@map("plots")\n}\n\nmodel HarvestLot {\n  id            String    @id @default(cuid())\n  blockNumber   String?\n  producerId    String\n  producer      Producer  @relation(fields: [producerId], references: [id], onDelete: Cascade)\n  plot          String?\n  harvestDate   DateTime?\n  classification String?\n  bales         Int       @default(0)\n  totalWeightKg Float     @default(0)\n  status        String    @default("colhido")\n  invoiceNumber String?\n  notes         String?\n  season        String    @default("2026")\n  createdAt     DateTime  @default(now())\n  updatedAt     DateTime  @updatedAt\n\n  @@map("harvest_lots")\n}\n'
    print('==> models Producer/Farm/Plot/HarvestLot adicionados')
elif 'stateRegistration' not in content:
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

mkdir -p "src/app/(dashboard)/producers"
cat > "src/app/(dashboard)/producers/page.tsx" << 'NOVAPRATA_EOF'
"use client"

import React from "react"
import Link from "next/link"
import { Search, UserPlus, Loader2, RefreshCcw, MapPin, LayoutGrid, Package, ArrowUpRight } from "lucide-react"

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

  const filtered = producers.filter(p =>
    p.name.toLowerCase().includes(searchTerm.toLowerCase())
  )

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

      <div className="relative flex-1 w-full">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4" style={{ color: "var(--text-tertiary)" }} />
        <Input
          placeholder="Buscar por nome..."
          className="pl-10 h-11"
          value={searchTerm}
          onChange={e => setSearchTerm(e.target.value)}
        />
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
import { ArrowLeft, Loader2, Phone, Mail, MessageCircle, MapPin, Building2, LayoutGrid, Package } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { AnimatedCounter } from "@/components/ui/animated-counter"
import { AuroraGlow } from "@/components/aurora-glow"
import { cn } from "@/lib/utils"

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
  const [producer, setProducer] = React.useState<any>(null)
  const [loading, setLoading] = React.useState(true)
  const [tab, setTab] = React.useState<(typeof TABS)[number]>("Fazendas e talhões")

  React.useEffect(() => {
    async function fetchProducer() {
      setLoading(true)
      try {
        const res = await fetch(`/api/producers/${params.id}`)
        if (res.ok) setProducer(await res.json())
      } catch (error) {
        console.error("Error fetching producer:", error)
      } finally {
        setLoading(false)
      }
    }
    if (params.id) fetchProducer()
  }, [params.id])

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

      <Button variant="ghost" size="sm" onClick={() => router.push("/producers")}>
        <ArrowLeft className="mr-2 h-4 w-4" />
        Voltar
      </Button>

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
          {(!producer.farms || producer.farms.length === 0) && (
            <Card><CardContent className="p-6 text-sm" style={{ color: "var(--text-tertiary)" }}>Nenhuma fazenda/talhão cadastrado ainda.</CardContent></Card>
          )}
          {(producer.farms || []).map((f: any) => (
            <Card key={f.id}>
              <CardContent className="p-5 sm:p-6">
                <p className="font-semibold text-sm mb-4 flex items-center gap-2" style={{ color: "var(--text-primary)" }}>
                  <MapPin className="h-4 w-4 text-emerald-500" />{f.name}
                </p>
                <table className="w-full text-sm">
                  <thead>
                    <tr style={{ borderBottom: "1px solid var(--border)" }}>
                      <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Talhão</th>
                      <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Área</th>
                      <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Variedade</th>
                    </tr>
                  </thead>
                  <tbody>
                    {f.plots.map((t: any) => (
                      <tr key={t.id} className="transition-colors duration-200 hover:bg-zinc-500/5" style={{ borderBottom: "1px solid var(--border)" }}>
                        <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{t.name}</td>
                        <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{t.areaHa} ha</td>
                        <td className="py-2.5" style={{ color: "var(--text-primary)" }}>
                          {t.variety}
                          {t.splitArea && <span className="ml-2 text-xs" style={{ color: "var(--text-tertiary)" }}>(área dividida)</span>}
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
                  </tr>
                </thead>
                <tbody>
                  {producer.harvestLots.map((l: any) => (
                    <tr key={l.id} className="transition-colors duration-200 hover:bg-zinc-500/5" style={{ borderBottom: "1px solid var(--border)" }}>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{l.blockNumber || "-"}</td>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{l.plot || "-"}</td>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{l.bales}</td>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{l.totalWeightKg}</td>
                      <td className="py-2.5"><Badge variant="ghost">{l.status}</Badge></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </CardContent>
        </Card>
      )}

      {tab === "Documentos" && (
        <Card><CardContent className="p-5 sm:p-6 text-sm" style={{ color: "var(--text-tertiary)" }}>Upload de documentos entra aqui (contratos, CAR, notas).</CardContent></Card>
      )}
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
echo "PRONTO. Visual premium aplicado (AuroraGlow, AnimatedCounter, icones"
echo "coloridos, hover states) igual ao padrao do Dashboard."
echo ""
echo "Próximos passos:"
echo "1) Se ainda nao rodou: SQL de prisma/manual-sql/producers_module.sql no Neon"
echo "2) npx prisma generate"
echo "3) npm run dev -> confere /producers"
echo "4) git add . && git commit -m 'feat: visual premium modulo produtores' && git push"
echo "==================================================================="
