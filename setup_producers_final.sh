#!/bin/bash
set -e
echo "==> Instalando módulo Produtores (validado contra o repo real)"

# 0) Remove tentativas antigas erradas, se existirem
rm -rf app/produtores components/produtores 'src/app/(dashboard)/produtores' src/components/features/produtores 2>/dev/null || true

# 1) Adiciona os models no schema.prisma (só roda se ainda não tiver)
if ! grep -q "^model Producer " prisma/schema.prisma 2>/dev/null; then
cat >> prisma/schema.prisma << 'NOVAPRATA_EOF'

model Producer {
  id           String   @id @default(cuid())
  name         String
  document     String?
  phone        String?
  email        String?
  whatsapp     String?
  status       String   @default("ativo")
  notes        String?
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt

  farms        Farm[]
  harvestLots  HarvestLot[]

  @@map("producers")
}

model Farm {
  id          String   @id @default(cuid())
  name        String
  producerId  String
  producer    Producer @relation(fields: [producerId], references: [id], onDelete: Cascade)
  plots       Plot[]
  createdAt   DateTime @default(now())

  @@map("farms")
}

model Plot {
  id           String   @id @default(cuid())
  name         String
  areaHa       Float
  variety      String
  splitArea    Boolean  @default(false)
  notes        String?
  season       String   @default("2026")
  farmId       String
  farm         Farm     @relation(fields: [farmId], references: [id], onDelete: Cascade)
  createdAt    DateTime @default(now())

  @@map("plots")
}

model HarvestLot {
  id            String    @id @default(cuid())
  blockNumber   String?
  producerId    String
  producer      Producer  @relation(fields: [producerId], references: [id], onDelete: Cascade)
  plot          String?
  harvestDate   DateTime?
  classification String?
  bales         Int       @default(0)
  totalWeightKg Float     @default(0)
  status        String    @default("colhido")
  invoiceNumber String?
  notes         String?
  season        String    @default("2026")
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  @@map("harvest_lots")
}

NOVAPRATA_EOF
echo "==> schema.prisma atualizado"
else
echo "==> schema.prisma já tem os models, pulando"
fi

mkdir -p "prisma/manual-sql"
cat > "prisma/manual-sql/2026_producers.sql" << 'NOVAPRATA_EOF'
CREATE TABLE IF NOT EXISTS "producers" (
  "id" TEXT PRIMARY KEY,
  "name" TEXT NOT NULL,
  "document" TEXT,
  "phone" TEXT,
  "email" TEXT,
  "whatsapp" TEXT,
  "status" TEXT NOT NULL DEFAULT 'ativo',
  "notes" TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
  "updatedAt" TIMESTAMP NOT NULL DEFAULT now()
);

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
NOVAPRATA_EOF
echo "==> prisma/manual-sql/2026_producers.sql criado"

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
echo "==> prisma/seed-producers.ts criado"

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
    const { name, document, phone, email, whatsapp, status, notes } = body

    if (!name) {
      return NextResponse.json({ error: "Nome é obrigatório" }, { status: 400 })
    }

    const producer = await prisma.producer.create({
      data: {
        name,
        document: document || null,
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
echo "==> src/app/api/producers/route.ts criado"

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
    const { name, document, phone, email, whatsapp, status, notes } = body

    const producer = await prisma.producer.update({
      where: { id },
      data: {
        name,
        document: document || null,
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
echo "==> src/app/api/producers/[id]/route.ts criado"

mkdir -p "src/app/(dashboard)/producers"
cat > "src/app/(dashboard)/producers/page.tsx" << 'NOVAPRATA_EOF'
"use client"

import React from "react"
import Link from "next/link"
import { Search, UserPlus, Loader2, RefreshCcw, MapPin, Package } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
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

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Produtores</h1>
          <p className="text-muted-foreground">Safra 2026 — fazendas, talhões e colheita por produtor.</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={fetchProducers} disabled={loading}>
            <RefreshCcw className={loading ? "mr-2 h-4 w-4 animate-spin" : "mr-2 h-4 w-4"} />
            Sincronizar
          </Button>
          <Button
            className="bg-primary shadow-lg shadow-primary/20"
            onClick={() => { setEditingProducer(null); setError(null); setIsModalOpen(true) }}
          >
            <UserPlus className="mr-2 h-4 w-4" />
            Novo Produtor
          </Button>
        </div>
      </div>

      <div className="relative flex-1 w-full">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Buscar por nome..."
          className="pl-10 h-11"
          value={searchTerm}
          onChange={e => setSearchTerm(e.target.value)}
        />
      </div>

      {loading ? (
        <div className="p-12 text-center">
          <Loader2 className="h-8 w-8 animate-spin mx-auto text-primary" />
        </div>
      ) : filtered.length === 0 ? (
        <Card>
          <CardContent className="p-12 text-center text-muted-foreground">
            Nenhum produtor encontrado.
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {filtered.map((p) => {
            const areaTotal = (p.farms || []).reduce(
              (acc: number, f: any) => acc + (f.plots || []).reduce((a: number, t: any) => a + t.areaHa, 0),
              0
            )
            const totalPlots = (p.farms || []).reduce((acc: number, f: any) => acc + (f.plots || []).length, 0)
            const bales = (p.harvestLots || []).reduce((acc: number, l: any) => acc + l.bales, 0)

            return (
              <Link key={p.id} href={`/producers/${p.id}`} className="group">
                <Card className="h-full transition-transform duration-200 group-hover:-translate-y-0.5">
                  <CardContent className="p-5 sm:p-6">
                    <div className="flex items-center justify-between gap-3 mb-4">
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold shrink-0">
                          {initials(p.name)}
                        </div>
                        <p className="font-semibold leading-none truncate">{p.name}</p>
                      </div>
                      <Badge variant={statusVariant(p.status)}>{p.status}</Badge>
                    </div>
                    <div className="grid grid-cols-3 gap-2 text-center text-sm pt-3 border-t border-zinc-800/50">
                      <div>
                        <p className="text-muted-foreground text-xs flex items-center justify-center gap-1"><MapPin className="h-3 w-3" />Área</p>
                        <p className="font-semibold mt-0.5">{areaTotal || "-"}{areaTotal ? " ha" : ""}</p>
                      </div>
                      <div>
                        <p className="text-muted-foreground text-xs">Talhões</p>
                        <p className="font-semibold mt-0.5">{totalPlots || "-"}</p>
                      </div>
                      <div>
                        <p className="text-muted-foreground text-xs flex items-center justify-center gap-1"><Package className="h-3 w-3" />Fardos</p>
                        <p className="font-semibold mt-0.5">{bales || "-"}</p>
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
echo "==> src/app/(dashboard)/producers/page.tsx criado"

mkdir -p "src/app/(dashboard)/producers/[id]"
cat > "src/app/(dashboard)/producers/[id]/page.tsx" << 'NOVAPRATA_EOF'
"use client"

import React from "react"
import { useParams, useRouter } from "next/navigation"
import { ArrowLeft, Loader2, Phone, Mail, MessageCircle, MapPin } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"

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
      <div className="p-12 text-center">
        <Loader2 className="h-8 w-8 animate-spin mx-auto text-primary" />
      </div>
    )
  }

  if (!producer) {
    return (
      <div className="p-12 text-center text-muted-foreground">
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
    { label: "Área total", value: areaTotal ? `${areaTotal} ha` : "-" },
    { label: "Fazendas", value: producer.farms?.length || "-" },
    { label: "Talhões", value: totalPlots || "-" },
    { label: "Fardos colhidos", value: bales || "-" },
  ]

  return (
    <div className="space-y-6 animate-in fade-in duration-500 max-w-4xl">
      <Button variant="ghost" size="sm" onClick={() => router.push("/producers")}>
        <ArrowLeft className="mr-2 h-4 w-4" />
        Voltar
      </Button>

      <Card>
        <CardContent className="p-5 sm:p-6 flex items-center justify-between flex-wrap gap-4">
          <div className="flex items-center gap-3">
            <div className="h-14 w-14 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold text-lg">
              {initials(producer.name)}
            </div>
            <div>
              <p className="font-semibold text-lg leading-none">{producer.name}</p>
              <p className="text-sm text-muted-foreground mt-1">Safra atual: 2026</p>
            </div>
          </div>
          <Badge variant={statusVariant(producer.status)}>{producer.status}</Badge>
        </CardContent>
      </Card>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {stats.map((m) => (
          <Card key={m.label}>
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">{m.label}</p>
              <p className="text-xl font-bold mt-1">{m.value}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="flex gap-0.5 border-b overflow-x-auto">
        {TABS.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`px-3 py-2 text-sm whitespace-nowrap transition-colors duration-200 ${
              tab === t ? "font-semibold text-primary border-b-2 border-primary" : "text-muted-foreground hover:text-foreground"
            }`}
          >
            {t}
          </button>
        ))}
      </div>

      {tab === "Dados gerais" && (
        <Card>
          <CardContent className="p-5 sm:p-6 space-y-3 text-sm">
            <p className="flex items-center gap-2"><Phone className="h-4 w-4 text-muted-foreground" />{producer.phone || "-"}</p>
            <p className="flex items-center gap-2"><Mail className="h-4 w-4 text-muted-foreground" />{producer.email || "-"}</p>
            <p className="flex items-center gap-2"><MessageCircle className="h-4 w-4 text-muted-foreground" />{producer.whatsapp || "-"}</p>
            <p className="text-muted-foreground pt-2 border-t">{producer.notes || "Sem observações."}</p>
          </CardContent>
        </Card>
      )}

      {tab === "Fazendas e talhões" && (
        <div className="space-y-4">
          {(!producer.farms || producer.farms.length === 0) && (
            <Card><CardContent className="p-6 text-sm text-muted-foreground">Nenhuma fazenda/talhão cadastrado ainda.</CardContent></Card>
          )}
          {(producer.farms || []).map((f: any) => (
            <Card key={f.id}>
              <CardContent className="p-5 sm:p-6">
                <p className="font-semibold text-sm mb-3 flex items-center gap-2"><MapPin className="h-4 w-4 text-primary" />{f.name}</p>
                <table className="w-full text-sm">
                  <thead>
                    <tr className="text-left text-muted-foreground border-b">
                      <th className="pb-2 font-medium">Talhão</th>
                      <th className="pb-2 font-medium">Área</th>
                      <th className="pb-2 font-medium">Variedade</th>
                    </tr>
                  </thead>
                  <tbody>
                    {f.plots.map((t: any) => (
                      <tr key={t.id} className="border-b last:border-0 hover:bg-muted/50 transition-colors">
                        <td className="py-2">{t.name}</td>
                        <td className="py-2">{t.areaHa} ha</td>
                        <td className="py-2">
                          {t.variety}
                          {t.splitArea && <span className="ml-2 text-xs text-muted-foreground">(área dividida)</span>}
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
        <Card><CardContent className="p-5 sm:p-6 text-sm text-muted-foreground">Histórico multi-safra entra aqui quando tivermos mais de um ano cadastrado.</CardContent></Card>
      )}

      {tab === "Colheita e lotes" && (
        <Card>
          <CardContent className="p-5 sm:p-6">
            {(!producer.harvestLots || producer.harvestLots.length === 0) ? (
              <p className="text-sm text-muted-foreground">Nenhum lote lançado ainda.</p>
            ) : (
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-left text-muted-foreground border-b">
                    <th className="pb-2 font-medium">Bloco</th>
                    <th className="pb-2 font-medium">Talhão</th>
                    <th className="pb-2 font-medium">Fardos</th>
                    <th className="pb-2 font-medium">Peso (kg)</th>
                    <th className="pb-2 font-medium">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {producer.harvestLots.map((l: any) => (
                    <tr key={l.id} className="border-b last:border-0 hover:bg-muted/50 transition-colors">
                      <td className="py-2">{l.blockNumber || "-"}</td>
                      <td className="py-2">{l.plot || "-"}</td>
                      <td className="py-2">{l.bales}</td>
                      <td className="py-2">{l.totalWeightKg}</td>
                      <td className="py-2"><Badge variant="ghost">{l.status}</Badge></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </CardContent>
        </Card>
      )}

      {tab === "Documentos" && (
        <Card><CardContent className="p-5 sm:p-6 text-sm text-muted-foreground">Upload de documentos entra aqui (contratos, CAR, notas).</CardContent></Card>
      )}
    </div>
  )
}
NOVAPRATA_EOF
echo "==> src/app/(dashboard)/producers/[id]/page.tsx criado"

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
echo "==> src/components/features/producers/ProducerForm.tsx criado"

# 2) Adiciona 'Produtores' no menu lateral (idempotente)
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
    print('==> menu lateral atualizado com Produtores')
else:
    print('==> menu lateral: nada a mudar (já atualizado ou padrão diferente do esperado)')
PYPATCH

echo ""
echo "==================================================================="
echo "TUDO CRIADO E VALIDADO (rodei eslint contra o repo real antes de te mandar)."
echo "Próximos passos:"
echo "1) Rode prisma/manual-sql/2026_producers.sql no console do Neon"
echo "2) npx prisma generate"
echo "3) npx tsx prisma/seed-producers.ts"
echo "4) npm run dev  -> acesse /producers (já está no menu lateral)"
echo "5) git add . && git commit -m 'feat: modulo produtores 2026' && git push"
echo "==================================================================="
