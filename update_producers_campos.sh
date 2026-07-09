#!/bin/bash
set -e
echo "==> Atualizando módulo Produtores: CNPJ/CPF, IE, endereço + limpeza de models antigos"

# 1) Remove models Produtor/Fazenda/Talhao/LoteColheita duplicados do schema.prisma (se existirem)
python3 << 'PYPATCH'
path = 'prisma/schema.prisma'
with open(path, encoding='utf-8') as f:
    content = f.read()

old_block = '''model Produtor {
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

'''

if old_block in content:
    content = content.replace(old_block, '')
    print('==> models antigos (Produtor/Fazenda/Talhao/LoteColheita) removidos')
else:
    print('==> models antigos não encontrados (já limpo ou schema diferente do esperado - confira manualmente)')

old_producer_head = '''model Producer {
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

new_producer_head = '''model Producer {
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

if old_producer_head in content:
    content = content.replace(old_producer_head, new_producer_head)
    print('==> model Producer expandido com stateRegistration e address')
elif 'stateRegistration' in content:
    print('==> model Producer já tem os campos novos, pulando')
else:
    print('==> ATENCAO: não encontrei o bloco esperado do model Producer - confira manualmente')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
PYPATCH

mkdir -p "prisma/manual-sql"
cat > "prisma/manual-sql/2026_producers_v2_campos.sql" << 'NOVAPRATA_EOF'
ALTER TABLE "producers" ADD COLUMN IF NOT EXISTS "stateRegistration" TEXT;
ALTER TABLE "producers" ADD COLUMN IF NOT EXISTS "address" TEXT;

DROP TABLE IF EXISTS "LoteColheita";
DROP TABLE IF EXISTS "Talhao";
DROP TABLE IF EXISTS "Fazenda";
DROP TABLE IF EXISTS "Produtor";
NOVAPRATA_EOF
echo "==> prisma/manual-sql/2026_producers_v2_campos.sql atualizado"

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
echo "==> src/app/api/producers/route.ts atualizado"

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
echo "==> src/app/api/producers/[id]/route.ts atualizado"

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
          <CardContent className="p-5 sm:p-6 space-y-4 text-sm">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-muted-foreground">CPF/CNPJ</p>
                <p className="mt-0.5">{producer.document || "-"}</p>
              </div>
              <div>
                <p className="text-xs text-muted-foreground">Inscrição Estadual</p>
                <p className="mt-0.5">{producer.stateRegistration || "-"}</p>
              </div>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Endereço</p>
              <p className="mt-0.5">{producer.address || "-"}</p>
            </div>
            <div className="pt-2 border-t space-y-3">
              <p className="flex items-center gap-2"><Phone className="h-4 w-4 text-muted-foreground" />{producer.phone || "-"}</p>
              <p className="flex items-center gap-2"><Mail className="h-4 w-4 text-muted-foreground" />{producer.email || "-"}</p>
              <p className="flex items-center gap-2"><MessageCircle className="h-4 w-4 text-muted-foreground" />{producer.whatsapp || "-"}</p>
            </div>
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
echo "==> src/app/(dashboard)/producers/[id]/page.tsx atualizado"

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
echo "==> src/components/features/producers/ProducerForm.tsx atualizado"

echo ""
echo "==================================================================="
echo "Próximos passos:"
echo "1) Rode prisma/manual-sql/2026_producers_v2_campos.sql no console do Neon"
echo "   (adiciona colunas novas + remove tabelas antigas não usadas, se existirem)"
echo "2) npx prisma generate"
echo "3) npx tsx prisma/seed-producers.ts   <- AINDA PENDENTE, roda pra popular André e José Olimpio"
echo "4) npm run dev -> confere /producers"
echo "5) git add . && git commit -m 'feat: cnpj/ie/endereco no modulo produtores' && git push"
echo "==================================================================="
