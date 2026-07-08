#!/usr/bin/env bash
set -e
echo "Escrevendo arquivos (rede, cofre, config, senha admin, premium)..."
mkdir -p "src/app/(dashboard)/dashboard"
cat > "src/app/(dashboard)/dashboard/page.tsx" << 'NOVAPRATA_EOF'
"use client"

import React from "react"
import Link from "next/link"
import {
  Box,
  Users,
  Wrench,
  AlertCircle,
  ArrowUpRight,
  Calendar,
  Loader2,
  TimerReset,
  ShieldCheck,
  ShieldAlert,
  Clock3,
} from "lucide-react"
import {
  AreaChart,
  Area,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { AnimatedCounter } from "@/components/ui/animated-counter"
import { cn } from "@/lib/utils"

type AssetStatusItem = {
  status: string
  _count: {
    _all: number
  }
}

type RecentAsset = {
  id: string
  tag: string
  name: string
  type: string
  createdAt: string
  sector: {
    name: string
  } | null
}

type SlaStats = {
  openTickets: number
  slaBreached: number
  slaWithin: number
  avgResolutionMinutes: number
  ticketsByDay: { date: string; abertos: number }[]
  ticketsByCategory: { category: string; count: number }[]
}

type DashboardStats = {
  totalAssets: number
  totalUsers: number
  maintenanceCount: number
  alertsCount: number
  assetsByStatus: AssetStatusItem[]
  recentAssets: RecentAsset[]
  sla: SlaStats
}

export default function DashboardPage() {
  const [stats, setStats] = React.useState<DashboardStats | null>(null)
  const [loading, setLoading] = React.useState(true)

  React.useEffect(() => {
    async function fetchStats() {
      try {
        const res = await fetch("/api/dashboard/stats")
        if (!res.ok) {
          throw new Error("Falha ao carregar dashboard")
        }
        const data = (await res.json()) as DashboardStats
        setStats(data)
      } catch (err) {
        console.error("Error fetching stats:", err)
      } finally {
        setLoading(false)
      }
    }

    fetchStats()
  }, [])

  if (loading) {
    return (
      <div className="flex h-[80vh] items-center justify-center">
        <Loader2 className="h-10 w-10 animate-spin text-primary" />
      </div>
    )
  }

  const statCards = [
    {
      title: "Total de Ativos",
      value: stats?.totalAssets || 0,
      description: "Equipamentos cadastrados",
      icon: Box,
      color: "text-blue-500",
      bg: "bg-blue-500/10",
      href: "/assets",
    },
    {
      title: "Em Manutencao",
      value: stats?.maintenanceCount || 0,
      description: "Chamados tecnicos ativos",
      icon: Wrench,
      color: "text-amber-500",
      bg: "bg-amber-500/10",
      href: "/maintenances",
    },
    {
      title: "Colaboradores",
      value: stats?.totalUsers || 0,
      description: "Usuarios com acesso",
      icon: Users,
      color: "text-emerald-500",
      bg: "bg-emerald-500/10",
      href: "/employees",
    },
    {
      title: "Alertas",
      value: stats?.alertsCount || 0,
      description: "Acoes sugeridas",
      icon: AlertCircle,
      color: "text-red-500",
      bg: "bg-red-500/10",
      href: "/reports",
    },
  ]

  return (
    <div className="space-y-10 animate-in fade-in duration-500">
      <div className="flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
        <div className="flex-1">
          <h1 className="text-3xl sm:text-4xl font-bold tracking-tight" style={{ color: "var(--text-primary)" }}>
            Dashboard
          </h1>
          <p className="text-sm mt-2" style={{ color: "var(--text-tertiary)" }}>
            Visao geral de seus ativos e operacoes
          </p>
        </div>
        <Button variant="outline" size="sm" className="w-fit">
          <Calendar className="mr-2 h-4 w-4" />
          <span className="text-xs sm:text-sm">{new Date().toLocaleDateString("pt-BR")}</span>
        </Button>
      </div>

      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {statCards.map((stat) => (
          <Link key={stat.title} href={stat.href} className="block">
            <Card className="group cursor-pointer hover:border-blue-200 hover:shadow-lg transition-all duration-200">
              <CardHeader className="flex flex-row items-start justify-between space-y-0 pb-3">
                <div className="flex-1">
                  <CardTitle className="text-xs sm:text-sm font-semibold" style={{ color: "var(--text-tertiary)" }}>
                    {stat.title}
                  </CardTitle>
                  <div
                    className="text-4xl sm:text-5xl font-bold mt-4"
                    style={{ letterSpacing: "-0.03em", color: "var(--text-primary)" }}
                  >
                    <AnimatedCounter value={stat.value} />
                  </div>
                </div>
                <div className={cn("p-3 rounded-xl flex-shrink-0", stat.bg)}>
                  <stat.icon className={cn("h-5 w-5", stat.color)} />
                </div>
              </CardHeader>
              <CardContent className="pt-0 flex items-center justify-between gap-2">
                <p className="text-xs" style={{ color: "var(--text-tertiary)" }}>
                  {stat.description}
                </p>
                <ArrowUpRight className="h-4 w-4 text-primary opacity-0 transition-opacity group-hover:opacity-100" />
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-4" style={{ color: "var(--text-primary)" }}>
          SLA de Chamados
        </h2>
        <div className="grid gap-6 sm:grid-cols-3 mb-6">
          <Card className="bg-emerald-500/5 border-emerald-500/20">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium flex items-center gap-2">
                <ShieldCheck className="h-4 w-4 text-emerald-500" /> Dentro do Prazo
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold"><AnimatedCounter value={stats?.sla?.slaWithin ?? 0} /></div>
              <p className="text-xs text-muted-foreground mt-1">Chamados no prazo do SLA</p>
            </CardContent>
          </Card>
          <Card className="bg-red-500/5 border-red-500/20">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium flex items-center gap-2">
                <ShieldAlert className="h-4 w-4 text-red-500" /> SLA Estourado
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold"><AnimatedCounter value={stats?.sla?.slaBreached ?? 0} /></div>
              <p className="text-xs text-muted-foreground mt-1">Precisam de atenção imediata</p>
            </CardContent>
          </Card>
          <Card className="bg-blue-500/5 border-blue-500/20">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium flex items-center gap-2">
                <Clock3 className="h-4 w-4 text-blue-500" /> Tempo Médio de Resolução
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">
                {stats?.sla?.avgResolutionMinutes
                  ? stats.sla.avgResolutionMinutes < 60
                    ? `${stats.sla.avgResolutionMinutes}min`
                    : `${(stats.sla.avgResolutionMinutes / 60).toFixed(1)}h`
                  : "—"}
              </div>
              <p className="text-xs text-muted-foreground mt-1">Média dos chamados concluídos</p>
            </CardContent>
          </Card>
        </div>

        <div className="grid gap-6 lg:grid-cols-2">
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-base font-semibold flex items-center gap-2">
                <TimerReset className="h-4 w-4 text-primary" /> Chamados Abertos (14 dias)
              </CardTitle>
              <CardDescription>Volume diário de novos chamados</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={220}>
                <AreaChart data={stats?.sla?.ticketsByDay || []}>
                  <defs>
                    <linearGradient id="colorAbertos" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.4} />
                      <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
                  <XAxis dataKey="date" fontSize={11} tickLine={false} />
                  <YAxis fontSize={11} tickLine={false} allowDecimals={false} width={28} />
                  <Tooltip />
                  <Area type="monotone" dataKey="abertos" stroke="#3b82f6" fill="url(#colorAbertos)" strokeWidth={2} />
                </AreaChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-base font-semibold">Chamados por Categoria</CardTitle>
              <CardDescription>As categorias que mais geram chamados</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={220}>
                <BarChart data={stats?.sla?.ticketsByCategory || []} layout="vertical" margin={{ left: 8 }}>
                  <CartesianGrid strokeDasharray="3 3" opacity={0.15} horizontal={false} />
                  <XAxis type="number" fontSize={11} allowDecimals={false} />
                  <YAxis type="category" dataKey="category" fontSize={11} width={90} tickLine={false} />
                  <Tooltip />
                  <Bar dataKey="count" fill="#3b82f6" radius={[0, 4, 4, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-7">
        <Card className="lg:col-span-4">
          <CardHeader className="pb-4">
            <CardTitle className="text-lg font-semibold" style={{ color: "var(--text-primary)" }}>
              Ativos Recentes
            </CardTitle>
            <CardDescription style={{ color: "var(--text-tertiary)" }}>
              Ultimos equipamentos adicionados
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {stats?.recentAssets?.length ? (
                stats.recentAssets.map((asset) => (
                  <Link
                    key={asset.id}
                    href={`/assets/${asset.id}`}
                    className="flex items-center gap-4 p-4 rounded-lg transition-all duration-200 hover:bg-blue-50"
                    style={{ background: "var(--bg-muted)", border: "1px solid var(--border-primary)" }}
                  >
                    <div
                      className="px-3 py-1.5 rounded-md font-semibold text-xs flex-shrink-0"
                      style={{ background: "rgba(37, 99, 235, 0.15)", color: "#3b82f6" }}
                    >
                      {asset.tag}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold truncate" style={{ color: "var(--text-primary)" }}>
                        {asset.name}
                      </p>
                      <p className="text-xs mt-0.5" style={{ color: "var(--text-tertiary)" }}>
                        {asset.type} • {asset.sector?.name || "Sem setor"}
                      </p>
                    </div>
                    <div className="text-xs whitespace-nowrap flex-shrink-0" style={{ color: "var(--text-muted)" }}>
                      {new Date(asset.createdAt).toLocaleDateString("pt-BR")}
                    </div>
                  </Link>
                ))
              ) : (
                <p className="text-sm text-center py-8" style={{ color: "var(--text-tertiary)" }}>
                  Nenhum ativo recente
                </p>
              )}
            </div>
          </CardContent>
        </Card>

        <Card className="lg:col-span-3">
          <CardHeader className="pb-4">
            <CardTitle className="text-lg font-semibold" style={{ color: "var(--text-primary)" }}>
              Status dos Ativos
            </CardTitle>
            <CardDescription style={{ color: "var(--text-tertiary)" }}>
              Distribuicao atual
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-5">
            {stats?.assetsByStatus?.length ? (
              stats.assetsByStatus.map((item) => (
                <div key={item.status} className="space-y-2.5">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-semibold" style={{ color: "var(--text-secondary)" }}>
                      {item.status}
                    </span>
                    <span
                      className="text-xs font-bold px-3 py-1.5 rounded-md"
                      style={{ color: "#3b82f6", background: "rgba(37, 99, 235, 0.1)" }}
                    >
                      {item._count._all}
                    </span>
                  </div>
                  <div className="h-2 w-full rounded-full overflow-hidden" style={{ background: "var(--border-primary)" }}>
                    <div
                      className="h-full transition-all duration-700 rounded-full"
                      style={{
                        width: `${(item._count._all / Math.max(stats.totalAssets || 1, 1)) * 100}%`,
                        background: "linear-gradient(90deg, #3b82f6, #60a5fa)",
                        boxShadow: "0 0 12px rgba(59, 130, 246, 0.3)",
                      }}
                    />
                  </div>
                </div>
              ))
            ) : (
              <p className="text-sm text-center py-8" style={{ color: "var(--text-tertiary)" }}>
                Sem dados
              </p>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

NOVAPRATA_EOF
mkdir -p "src/app/(dashboard)/documents"
cat > "src/app/(dashboard)/documents/page.tsx" << 'NOVAPRATA_EOF'
"use client"

import React from "react"
import { FileText, AlertTriangle, CheckCircle2, Plus, Loader2, Pencil, Trash2, RefreshCw } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { cn } from "@/lib/utils"
import { DocumentForm } from "@/components/features/documents/DocumentForm"
import { useConfirm } from "@/components/confirm-dialog-provider"
import { useToast } from "@/components/toast-provider"

function daysUntil(date: string) {
  const diff = new Date(date).getTime() - Date.now()
  return Math.ceil(diff / (1000 * 60 * 60 * 24))
}

export default function DocumentsPage() {
  const confirmDialog = useConfirm()
  const { success, error: toastError } = useToast()
  const [documents, setDocuments] = React.useState<any[]>([])
  const [suppliers, setSuppliers] = React.useState<any[]>([])
  const [assets, setAssets] = React.useState<any[]>([])
  const [loading, setLoading] = React.useState(true)
  const [isModalOpen, setIsModalOpen] = React.useState(false)
  const [editingDoc, setEditingDoc] = React.useState<any>(null)

  const fetchData = React.useCallback(async () => {
    setLoading(true)
    try {
      const [dRes, sRes, aRes] = await Promise.all([
        fetch("/api/documents"),
        fetch("/api/suppliers"),
        fetch("/api/assets"),
      ])
      const dData = await dRes.json()
      const sData = await sRes.json()
      const aData = await aRes.json()
      if (Array.isArray(dData)) setDocuments(dData)
      if (Array.isArray(sData)) setSuppliers(sData)
      if (Array.isArray(aData)) setAssets(aData)
    } catch (error) {
      console.error("Error fetching documents:", error)
    } finally {
      setLoading(false)
    }
  }, [])

  React.useEffect(() => { fetchData() }, [fetchData])

  async function handleCreateOrUpdate(data: any) {
    const url = editingDoc ? `/api/documents/${editingDoc.id}` : "/api/documents"
    const method = editingDoc ? "PUT" : "POST"
    try {
      const res = await fetch(url, {
        method,
        body: JSON.stringify(data),
        headers: { "Content-Type": "application/json" },
      })
      if (res.ok) {
        setIsModalOpen(false)
        setEditingDoc(null)
        success(editingDoc ? "Registro atualizado" : "Registro cadastrado")
        fetchData()
      } else {
        toastError("Erro ao salvar registro")
      }
    } catch (error) {
      console.error("Error saving document:", error)
      toastError("Erro ao salvar registro")
    }
  }

  async function handleDelete(id: string) {
    const ok = await confirmDialog({ title: "Excluir certificado/licença", message: "Deseja realmente excluir este registro? Essa ação não pode ser desfeita.", destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/documents/${id}`, { method: "DELETE" })
      if (res.ok) {
        success("Registro excluído")
        fetchData()
      } else {
        toastError("Erro ao excluir registro")
      }
    } catch (error) {
      console.error("Error deleting document:", error)
      toastError("Erro ao excluir registro")
    }
  }

  const expiredCount = documents.filter(d => daysUntil(d.validUntil) < 0).length
  const expiringSoonCount = documents.filter(d => { const days = daysUntil(d.validUntil); return days >= 0 && days <= 60 }).length
  const okCount = documents.filter(d => daysUntil(d.validUntil) > 60).length

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Certificados e Licenças</h1>
          <p className="text-muted-foreground">Controle de vencimento de certificados digitais e licenças de software.</p>
        </div>
        <Button className="bg-primary shadow-lg shadow-primary/20" onClick={() => { setEditingDoc(null); setIsModalOpen(true) }}>
          <Plus className="mr-2 h-4 w-4" />
          Cadastrar
        </Button>
      </div>

      <div className="grid gap-6 md:grid-cols-3">
        <Card className="bg-red-500/5 border-red-500/20">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <AlertTriangle className="h-4 w-4 text-red-500" /> Vencidos
            </CardTitle>
          </CardHeader>
          <CardContent><div className="text-2xl font-bold">{String(expiredCount).padStart(2, '0')}</div></CardContent>
        </Card>
        <Card className="bg-amber-500/5 border-amber-500/20">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <AlertTriangle className="h-4 w-4 text-amber-500" /> Vencendo em 60 dias
            </CardTitle>
          </CardHeader>
          <CardContent><div className="text-2xl font-bold">{String(expiringSoonCount).padStart(2, '0')}</div></CardContent>
        </Card>
        <Card className="bg-emerald-500/5 border-emerald-500/20">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <CheckCircle2 className="h-4 w-4 text-emerald-500" /> Em dia
            </CardTitle>
          </CardHeader>
          <CardContent><div className="text-2xl font-bold">{String(okCount).padStart(2, '0')}</div></CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Lista</CardTitle>
            <CardDescription>Ordenado por data de vencimento mais próxima.</CardDescription>
          </div>
          <Button variant="outline" size="sm" onClick={fetchData} disabled={loading}>
            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="mr-2 h-4 w-4" />}
            Sincronizar
          </Button>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y relative min-h-[300px]">
            {loading ? (
              <div className="absolute inset-0 flex items-center justify-center bg-background/50 backdrop-blur-[1px]">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
              </div>
            ) : documents.length === 0 ? (
              <div className="p-12 text-center text-muted-foreground">Nenhum certificado ou licença cadastrado.</div>
            ) : (
              documents.map((d) => {
                const days = daysUntil(d.validUntil)
                const statusColor = days < 0 ? "text-red-500 bg-red-500/10" : days <= 60 ? "text-amber-500 bg-amber-500/10" : "text-emerald-500 bg-emerald-500/10"
                return (
                  <div key={d.id} className="p-4 hover:bg-muted/50 transition-colors flex items-center justify-between group">
                    <div className="flex items-center gap-4">
                      <div className={cn("p-2 rounded-full", statusColor)}>
                        <FileText className="h-5 w-5" />
                      </div>
                      <div>
                        <div className="flex items-center gap-2 flex-wrap">
                          <p className="font-semibold text-sm">{d.title}</p>
                          <Badge variant="outline" className="text-[10px] font-normal py-0 h-4">
                            {d.type === "CERTIFICADO" ? "Certificado" : "Licença"}
                          </Badge>
                        </div>
                        <p className="text-xs text-muted-foreground mt-1">
                          {d.holder} — vence em {new Date(d.validUntil).toLocaleDateString()}
                          {" "}({days < 0 ? `vencido há ${Math.abs(days)} dias` : `${days} dias`})
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Button variant="ghost" size="icon" className="h-8 w-8 text-muted-foreground hover:text-primary" onClick={() => { setEditingDoc(d); setIsModalOpen(true) }}>
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button variant="ghost" size="icon" className="h-8 w-8 text-destructive hover:text-destructive" onClick={() => handleDelete(d.id)}>
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                )
              })
            )}
          </div>
        </CardContent>
      </Card>

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingDoc ? "Editar Registro" : "Novo Certificado/Licença"}>
        <DocumentForm
          initialData={editingDoc}
          suppliers={suppliers}
          assets={assets}
          onCancel={() => setIsModalOpen(false)}
          onSubmit={handleCreateOrUpdate}
        />
      </Modal>
    </div>
  )
}

NOVAPRATA_EOF
mkdir -p "src/app/(dashboard)/employees"
cat > "src/app/(dashboard)/employees/page.tsx" << 'NOVAPRATA_EOF'
"use client"

import React from "react"
import {
  Search,
  Mail,
  Phone,
  Pencil,
  Trash2,
  UserPlus,
  Loader2,
  RefreshCcw
} from "lucide-react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { useConfirm } from "@/components/confirm-dialog-provider"
import { useToast } from "@/components/toast-provider"
import { EmployeeForm } from "@/components/features/employees/EmployeeForm"

export default function EmployeesPage() {
  const confirmDialog = useConfirm()
  const { success, error: toastError } = useToast()
  const [employees, setEmployees] = React.useState<any[]>([])
  const [loading, setLoading] = React.useState(true)
  const [searchTerm, setSearchTerm] = React.useState("")
  const [isModalOpen, setIsModalOpen] = React.useState(false)
  const [editingEmployee, setEditingEmployee] = React.useState<any>(null)
  const [error, setError] = React.useState<string | null>(null)

  const fetchEmployees = React.useCallback(async () => {
    setLoading(true)
    try {
      const res = await fetch("/api/employees")
      const data = await res.json()
      if (Array.isArray(data)) setEmployees(data)
    } catch (error) {
      console.error("Error fetching employees:", error)
    } finally {
      setLoading(false)
    }
  }, [])

  React.useEffect(() => {
    fetchEmployees()
  }, [fetchEmployees])

  async function handleCreateOrUpdate(data: any) {
    setError(null)
    const url = editingEmployee ? `/api/employees/${editingEmployee.id}` : "/api/employees"
    const method = editingEmployee ? "PUT" : "POST"
    try {
      const res = await fetch(url, {
        method,
        body: JSON.stringify(data),
        headers: { "Content-Type": "application/json" },
      })
      const result = await res.json()
      if (res.ok) {
        setIsModalOpen(false)
        setEditingEmployee(null)
        success(editingEmployee ? "Colaborador atualizado" : "Colaborador criado")
        fetchEmployees()
      } else {
        setError(result.error || "Erro ao salvar colaborador")
      }
    } catch (err) {
      console.error("Error saving employee:", err)
      setError("Erro ao salvar colaborador")
    }
  }

  async function handleDelete(id: string) {
    const ok = await confirmDialog({ title: "Excluir colaborador", message: "Deseja realmente excluir este colaborador?", destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/employees/${id}`, { method: "DELETE" })
      const result = await res.json()
      if (res.ok) {
        success("Colaborador excluído")
        fetchEmployees()
      } else {
        toastError(result.error || "Erro ao excluir colaborador")
      }
    } catch (error) {
      console.error("Error deleting employee:", error)
      toastError("Erro ao excluir colaborador")
    }
  }

  const filtered = employees.filter(emp =>
    emp.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    emp.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (emp.department || "").toLowerCase().includes(searchTerm.toLowerCase())
  )

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Colaboradores</h1>
          <p className="text-muted-foreground">Gerencie o inventário de ativos por pessoa e departamento.</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={fetchEmployees} disabled={loading}>
            <RefreshCcw className={loading ? "mr-2 h-4 w-4 animate-spin" : "mr-2 h-4 w-4"} />
            Sincronizar
          </Button>
          <Button
            className="bg-primary shadow-lg shadow-primary/20"
            onClick={() => { setEditingEmployee(null); setError(null); setIsModalOpen(true) }}
          >
            <UserPlus className="mr-2 h-4 w-4" />
            Novo Colaborador
          </Button>
        </div>
      </div>

      <div className="relative flex-1 w-full">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Buscar por nome, e-mail ou setor..."
          className="pl-10 h-11"
          value={searchTerm}
          onChange={e => setSearchTerm(e.target.value)}
        />
      </div>

      <Card>
        <CardContent className="p-0">
          <div className="relative w-full overflow-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-muted/30">
                  <th className="h-12 px-4 text-left font-medium text-muted-foreground">Colaborador</th>
                  <th className="h-12 px-4 text-left font-medium text-muted-foreground">Cargo / Setor</th>
                  <th className="h-12 px-4 text-left font-medium text-muted-foreground">Nível</th>
                  <th className="h-12 px-4 text-center font-medium text-muted-foreground">Ativos</th>
                  <th className="h-12 px-4 text-left font-medium text-muted-foreground">Status</th>
                  <th className="h-12 px-4 text-right font-medium text-muted-foreground">Ações</th>
                </tr>
              </thead>
              <tbody className="[&_tr:last-child]:border-0">
                {loading ? (
                  <tr>
                    <td colSpan={6} className="p-8 text-center">
                      <Loader2 className="h-8 w-8 animate-spin mx-auto text-primary" />
                    </td>
                  </tr>
                ) : filtered.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="p-8 text-center text-muted-foreground">
                      Nenhum colaborador encontrado.
                    </td>
                  </tr>
                ) : filtered.map((person) => (
                  <tr key={person.id} className="border-b transition-colors hover:bg-muted/50 group">
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold">
                          {person.name[0]}
                        </div>
                        <div>
                          <p className="font-semibold leading-none">{person.name}</p>
                          <p className="text-xs text-muted-foreground mt-1 flex items-center gap-1">
                            <Mail className="h-3 w-3" /> {person.email}
                          </p>
                          {person.phone && (
                            <p className="text-xs text-muted-foreground mt-0.5 flex items-center gap-1">
                              <Phone className="h-3 w-3" /> {person.phone}
                            </p>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="p-4 align-middle">
                      <p className="text-sm">{person.jobTitle || "—"}</p>
                      <p className="text-xs text-muted-foreground">{person.department || "Sem setor"}</p>
                    </td>
                    <td className="p-4 align-middle">
                      <Badge variant="secondary" className="font-normal">{person.role}</Badge>
                    </td>
                    <td className="p-4 text-center">
                      <div className="inline-flex items-center justify-center h-7 w-7 rounded-full bg-zinc-100 dark:bg-zinc-800 font-bold">
                        {person._count?.assets || 0}
                      </div>
                    </td>
                    <td className="p-4">
                      <Badge variant={person.status === "INATIVO" ? "outline" : "success"}>
                        {person.status || "ATIVO"}
                      </Badge>
                    </td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8 text-muted-foreground hover:text-primary"
                          onClick={() => { setEditingEmployee(person); setError(null); setIsModalOpen(true) }}
                        >
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8 text-destructive hover:text-destructive"
                          onClick={() => handleDelete(person.id)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingEmployee ? "Editar Colaborador" : "Novo Colaborador"}
      >
        {error && (
          <div className="mb-4 p-3 rounded-md bg-red-500/10 border border-red-500/20 text-sm text-red-500">
            {error}
          </div>
        )}
        <EmployeeForm
          initialData={editingEmployee}
          onCancel={() => setIsModalOpen(false)}
          onSubmit={handleCreateOrUpdate}
        />
      </Modal>
    </div>
  )
}

NOVAPRATA_EOF
mkdir -p "src/app/(dashboard)"
cat > "src/app/(dashboard)/layout-client.tsx" << 'NOVAPRATA_EOF'
"use client"

import React from "react"
import Link from "next/link"
import { usePathname, useRouter } from "next/navigation"
import { Monitor, LayoutDashboard, Box, Users, Lock, Network, PenTool, BarChart3, Settings, ChevronLeft, Search, LogOut, User, Ticket, FileText, Building2 } from "lucide-react"
import { motion } from "framer-motion"
import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import { ThemeToggle } from "@/components/theme-toggle"
import { ToastQueueProvider } from "@/components/toast-provider"
import { ConfirmDialogProvider } from "@/components/confirm-dialog-provider"
import { CommandPalette } from "@/components/command-palette"
import { NotificationBell } from "@/components/notification-bell"

const sidebarItems = [
  { icon: LayoutDashboard, label: "Dashboard", href: "/dashboard" },
  { icon: Box, label: "Ativos", href: "/assets" },
  { icon: Users, label: "Pessoas", href: "/employees" },
  { icon: Lock, label: "Cofre", href: "/vault" },
  { icon: Network, label: "Rede", href: "/network" },
  { icon: PenTool, label: "Manutenção", href: "/maintenances" },
  { icon: Ticket, label: "Chamados", href: "/tickets" },
  { icon: FileText, label: "Certificados/Licenças", href: "/documents" },
  { icon: Building2, label: "Fornecedores", href: "/suppliers" },
  { icon: BarChart3, label: "Relatórios", href: "/reports" },
]

export function DashboardLayoutClient({
  children,
}: {
  children: React.ReactNode
}) {
  const [isCollapsed, setIsCollapsed] = React.useState(false)
  const pathname = usePathname()
  const router = useRouter()

  async function handleLogout() {
    try {
      await fetch("/api/auth/logout", { method: "POST" })
    } finally {
      router.push("/login")
      router.refresh()
    }
  }

  return (
    <ToastQueueProvider>
    <ConfirmDialogProvider>
    <div className="flex min-h-screen" style={{ background: "var(--bg-primary)", color: "var(--text-primary)" }}>
      <CommandPalette />
      {/* Sidebar */}
      <aside
        className={cn(
          "fixed left-0 top-0 z-40 h-screen border-r transition-all duration-300 ease-in-out",
          isCollapsed ? "w-16" : "w-64"
        )}
        style={{ background: "var(--sidebar-bg)", borderColor: "var(--sidebar-border)" }}
      >
        <div className="flex h-14 items-center justify-between px-3 sm:px-4">
          <Link href="/dashboard" className="flex items-center gap-2 overflow-hidden py-2">
            <div className="min-w-[32px] bg-primary/90 p-1.5 rounded-lg hover:bg-primary transition-colors">
              <Monitor className="w-5 h-5 text-white" />
            </div>
            {!isCollapsed && (
              <span className="text-sm font-semibold tracking-tight whitespace-nowrap" style={{ color: "var(--text-primary)" }}>
                NovaPrata Labs
              </span>
            )}
          </Link>
          {!isCollapsed && (
            <Button
              variant="ghost"
              size="icon"
              className="h-7 w-7"
              onClick={() => setIsCollapsed(true)}
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
          )}
          {isCollapsed && (
            <Button
              variant="ghost"
              size="icon"
              className="absolute -right-3.5 top-14 h-7 w-7 rounded-full border"
              onClick={() => setIsCollapsed(false)}
              style={{ borderColor: "var(--border-primary)" }}
            >
              <ChevronLeft className={cn("h-4 w-4 transition-transform duration-200", isCollapsed && "rotate-180")} />
            </Button>
          )}
        </div>

        <nav className="mt-6 flex flex-col gap-1.5 px-2 sm:px-3">
          {sidebarItems.map((item) => {
            const active = pathname === item.href
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  "relative flex items-center gap-3 rounded-lg px-3 py-2.5 text-xs sm:text-sm font-medium transition-colors duration-200",
                  active ? "text-[var(--sidebar-item-active-text)]" : "text-zinc-600 hover:text-zinc-800"
                )}
                onMouseEnter={(e) => {
                  if (!active) e.currentTarget.style.background = "var(--sidebar-item-hover)"
                }}
                onMouseLeave={(e) => {
                  if (!active) e.currentTarget.style.background = "transparent"
                }}
              >
                {active && (
                  <motion.div
                    layoutId="sidebar-active-pill"
                    className="absolute inset-0 rounded-lg border"
                    style={{
                      background: "var(--sidebar-item-active-bg)",
                      borderColor: "var(--sidebar-item-active-border)",
                      boxShadow: "var(--sidebar-item-active-shadow)",
                    }}
                    transition={{ type: "spring", stiffness: 400, damping: 32 }}
                  />
                )}
                <item.icon className={cn("relative h-4 w-4 sm:h-5 sm:w-5 min-w-[16px] sm:min-w-[20px] flex-shrink-0 transition-all", active ? "opacity-100" : "opacity-60")} />
                {!isCollapsed && <span className="relative whitespace-nowrap truncate">{item.label}</span>}
              </Link>
            )
          })}
        </nav>

        <div className="absolute bottom-4 left-0 w-full px-2 sm:px-3 space-y-1">
          <div className="mb-4 h-px mx-0.5" style={{ background: "var(--border-primary)" }} />
          <Link
            href="/settings"
            className={cn(
              "flex items-center gap-3 rounded-lg px-3 py-2.5 text-xs sm:text-sm font-medium transition-all duration-200"
            )}
            style={{ color: "var(--text-tertiary)" }}
            onMouseEnter={(e) => {
              e.currentTarget.style.background = "var(--sidebar-item-hover)"
              e.currentTarget.style.color = "var(--text-secondary)"
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.background = "transparent"
              e.currentTarget.style.color = "var(--text-tertiary)"
            }}
          >
            <Settings className="h-4 w-4 sm:h-5 sm:w-5 min-w-[16px] sm:min-w-[20px] flex-shrink-0" />
            {!isCollapsed && <span className="whitespace-nowrap">Configurações</span>}
          </Link>
          <button
            type="button"
            className={cn(
              "flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-left text-xs sm:text-sm font-medium transition-all duration-200"
            )}
            style={{ color: "var(--text-tertiary)" }}
            onClick={handleLogout}
            onMouseEnter={(e) => {
              e.currentTarget.style.background = "var(--status-error-bg)"
              e.currentTarget.style.color = "var(--status-error)"
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.background = "transparent"
              e.currentTarget.style.color = "var(--text-tertiary)"
            }}
          >
            <LogOut className="h-4 w-4 sm:h-5 sm:w-5 min-w-[16px] sm:min-w-[20px] flex-shrink-0" />
            {!isCollapsed && <span className="whitespace-nowrap">Sair</span>}
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main
        className={cn(
          "flex-1 transition-all duration-300",
          isCollapsed ? "pl-16" : "pl-64"
        )}
      >
        {/* Topbar */}
        <header className="sticky top-0 z-30 flex h-14 items-center justify-between border-b px-4 sm:px-6 gap-4" style={{ background: "var(--topbar-bg)", borderColor: "var(--topbar-border)" }}>
          <div className="relative w-full max-w-xs">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2" style={{ color: "var(--text-tertiary)" }} />
            <input
              type="text"
              readOnly
              placeholder="Buscar (Cmd + K)"
              className="h-9 w-full rounded-lg pl-9 pr-3 text-sm transition-all duration-200 focus:outline-none focus:ring-1 border cursor-pointer"
              style={{
                background: "var(--input-bg)",
                borderColor: "var(--input-border)",
                color: "var(--input-text)",
              }}
              onClick={() => (window as any).__openCommandPalette?.()}
              onFocus={(e) => {
                e.currentTarget.blur()
                ;(window as any).__openCommandPalette?.()
              }}
            />
          </div>

          <div className="flex items-center gap-2 sm:gap-3 ml-auto">
            <ThemeToggle />
            <NotificationBell />
            <div className="h-6 w-px hidden sm:block" style={{ background: "var(--border-primary)" }} />
            <div className="flex items-center gap-2 sm:gap-3">
              <div className="text-right hidden sm:flex flex-col gap-0.5">
                <p className="text-xs sm:text-sm font-medium" style={{ color: "var(--text-primary)" }}>Admin User</p>
                <p className="text-xs" style={{ color: "var(--text-tertiary)" }}>TI Manager</p>
              </div>
              <div className="h-8 w-8 rounded-lg flex items-center justify-center font-bold border flex-shrink-0" style={{ background: "rgba(37, 99, 235, 0.1)", borderColor: "rgba(37, 99, 235, 0.3)", color: "#2563eb" }}>
                <User className="h-4 w-4" />
              </div>
            </div>
          </div>
        </header>

        {/* Page Content */}
        <div className="p-4 sm:p-6 lg:p-8 min-h-screen" style={{ background: "var(--bg-primary)" }}>
          {children}
        </div>
      </main>
    </div>
    </ConfirmDialogProvider>
    </ToastQueueProvider>
  )
}

NOVAPRATA_EOF
mkdir -p "src/app/(dashboard)/network"
cat > "src/app/(dashboard)/network/page.tsx" << 'NOVAPRATA_EOF'
"use client"

import React from "react"
import {
  Network,
  Activity,
  Globe,
  Server,
  Search,
  Zap,
  ShieldCheck,
  Plus,
  Pencil,
  Trash2,
  Loader2,
} from "lucide-react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { useConfirm } from "@/components/confirm-dialog-provider"
import { useToast } from "@/components/toast-provider"

type NetworkSegment = {
  id: string
  name: string
  gateway: string
  vlan: string
  cidr: string
  totalIps: number
  usedIps: number
  usagePercent: number
  status: string
}

type NetworkOverview = {
  summary: {
    gatewayCoreStatus: string
    vpnActive: number
    networkDevices: number
    ipsProtection: string
    totalSegments: number
    degradedSegments: number
  }
  segments: NetworkSegment[]
}

const initialSegmentForm = {
  name: "",
  gateway: "",
  vlan: "",
  cidr: "",
  totalIps: 254,
}

export default function NetworkPage() {
  const confirmDialog = useConfirm()
  const { success, error: toastError } = useToast()
  const [overview, setOverview] = React.useState<NetworkOverview | null>(null)
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState<string | null>(null)
  const [searchTerm, setSearchTerm] = React.useState("")
  const [isModalOpen, setIsModalOpen] = React.useState(false)
  const [segmentForm, setSegmentForm] = React.useState(initialSegmentForm)
  const [savingSegment, setSavingSegment] = React.useState(false)
  const [editingSegmentId, setEditingSegmentId] = React.useState<string | null>(null)

  const fetchOverview = React.useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const res = await fetch("/api/network/overview")
      const data = (await res.json().catch(() => ({}))) as NetworkOverview & { error?: string }
      if (!res.ok) {
        throw new Error(data.error || "Falha ao carregar infraestrutura de rede")
      }
      setOverview(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro inesperado")
    } finally {
      setLoading(false)
    }
  }, [])

  React.useEffect(() => {
    fetchOverview()
  }, [fetchOverview])

  const filteredSegments = (overview?.segments || []).filter((segment) => {
    const term = searchTerm.toLowerCase()
    return (
      segment.name.toLowerCase().includes(term) ||
      segment.gateway.toLowerCase().includes(term) ||
      segment.vlan.toLowerCase().includes(term) ||
      segment.cidr.toLowerCase().includes(term)
    )
  })

  async function handleSaveSegment(e: React.FormEvent) {
    e.preventDefault()
    setSavingSegment(true)
    try {
      const url = editingSegmentId ? `/api/network/segments/${editingSegmentId}` : "/api/network/segments"
      const method = editingSegmentId ? "PUT" : "POST"
      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(segmentForm),
      })

      const data = (await res.json().catch(() => ({}))) as { error?: string }
      if (!res.ok) {
        throw new Error(data.error || "Nao foi possivel salvar a VLAN")
      }

      setSegmentForm(initialSegmentForm)
      setEditingSegmentId(null)
      setIsModalOpen(false)
      success(editingSegmentId ? "VLAN atualizada" : "VLAN criada")
      await fetchOverview()
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro inesperado")
      toastError(err instanceof Error ? err.message : "Erro inesperado")
    } finally {
      setSavingSegment(false)
    }
  }

  function openEditSegment(segment: NetworkSegment) {
    setEditingSegmentId(segment.id)
    setSegmentForm({
      name: segment.name,
      gateway: segment.gateway,
      vlan: segment.vlan,
      cidr: segment.cidr,
      totalIps: segment.totalIps,
    })
    setIsModalOpen(true)
  }

  function openNewSegment() {
    setEditingSegmentId(null)
    setSegmentForm(initialSegmentForm)
    setIsModalOpen(true)
  }

  async function handleDeleteSegment(id: string) {
    const ok = await confirmDialog({ title: "Excluir VLAN", message: "Deseja realmente excluir esta VLAN/segmento?", destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/network/segments/${id}`, { method: "DELETE" })
      const data = (await res.json().catch(() => ({}))) as { error?: string }
      if (!res.ok) {
        throw new Error(data.error || "Erro ao excluir segmento")
      }
      success("VLAN excluída")
      await fetchOverview()
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro inesperado")
      toastError(err instanceof Error ? err.message : "Erro inesperado")
    }
  }

  const gatewayUp = overview?.summary.gatewayCoreStatus === "UP"
  const ipsProtectionActive = overview?.summary.ipsProtection === "ACTIVE"

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Rede e Infraestrutura</h1>
          <p className="text-muted-foreground">Dados de conectividade e segmentacao alimentados pelo banco.</p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" onClick={fetchOverview} disabled={loading}>
            {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Zap className="mr-2 h-4 w-4" />}
            Atualizar
          </Button>
          <Button className="bg-primary" onClick={openNewSegment}>
            <Plus className="mr-2 h-4 w-4" />
            Nova VLAN
          </Button>
        </div>
      </div>

      {error && (
        <Card className="border-destructive/30 bg-destructive/5">
          <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
        </Card>
      )}

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card className="bg-emerald-500/5 border-emerald-500/20">
          <CardContent className="p-4 flex items-center justify-between">
            <div className="space-y-1">
              <p className="text-xs font-medium text-muted-foreground">Gateway Core</p>
              <p className="text-2xl font-bold text-emerald-600">{gatewayUp ? "UP" : "DOWN"}</p>
            </div>
            <Activity className="h-8 w-8 text-emerald-500 opacity-50" />
          </CardContent>
        </Card>
        <Card className="bg-blue-500/5 border-blue-500/20">
          <CardContent className="p-4 flex items-center justify-between">
            <div className="space-y-1">
              <p className="text-xs font-medium text-muted-foreground">VPN Ativas</p>
              <p className="text-2xl font-bold text-blue-600">{overview?.summary.vpnActive ?? 0}</p>
            </div>
            <Globe className="h-8 w-8 text-blue-500 opacity-50" />
          </CardContent>
        </Card>
        <Card className="bg-indigo-500/5 border-indigo-500/20">
          <CardContent className="p-4 flex items-center justify-between">
            <div className="space-y-1">
              <p className="text-xs font-medium text-muted-foreground">Dispositivos Rede</p>
              <p className="text-2xl font-bold text-indigo-600">{overview?.summary.networkDevices ?? 0}</p>
            </div>
            <Server className="h-8 w-8 text-indigo-500 opacity-50" />
          </CardContent>
        </Card>
        <Card className="bg-sky-500/5 border-sky-500/20">
          <CardContent className="p-4 flex items-center justify-between">
            <div className="space-y-1">
              <p className="text-xs font-medium text-muted-foreground">Protecao IPS</p>
              <p className="text-2xl font-bold text-sky-600">{ipsProtectionActive ? "ACTIVE" : "ATENCAO"}</p>
            </div>
            <ShieldCheck className="h-8 w-8 text-sky-500 opacity-50" />
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <CardTitle>Inventario de Redes</CardTitle>
              <CardDescription>Sub-redes cadastradas e uso de IPs em tempo real.</CardDescription>
            </div>
            <div className="relative w-full md:w-72">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Filtrar VLANs..."
                className="pl-10 h-10"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-muted/30">
                <th className="h-12 px-4 text-left font-medium text-muted-foreground">Nome da Rede</th>
                <th className="h-12 px-4 text-left font-medium text-muted-foreground">Gateway</th>
                <th className="h-12 px-4 text-left font-medium text-muted-foreground text-center">VLAN ID</th>
                <th className="h-12 px-4 text-left font-medium text-muted-foreground">Uso de IPs</th>
                <th className="h-12 px-4 text-left font-medium text-muted-foreground">Status</th>
                <th className="h-12 px-4 text-right font-medium text-muted-foreground">Acoes</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={6} className="p-8 text-center">
                    <Loader2 className="h-8 w-8 animate-spin mx-auto text-primary" />
                  </td>
                </tr>
              ) : filteredSegments.length === 0 ? (
                <tr>
                  <td colSpan={6} className="p-8 text-center text-muted-foreground">
                    Nenhuma rede encontrada.
                  </td>
                </tr>
              ) : (
                filteredSegments.map((segment) => (
                  <tr key={segment.id} className="border-b transition-colors hover:bg-muted/50 group">
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        <Network className="h-5 w-5 text-primary" />
                        <div className="min-w-0">
                          <span className="font-semibold block truncate">{segment.name}</span>
                          <span className="text-xs text-muted-foreground">{segment.cidr}</span>
                        </div>
                      </div>
                    </td>
                    <td className="p-4 align-middle font-mono text-xs">{segment.gateway}</td>
                    <td className="p-4 text-center">
                      <Badge variant="secondary" className="font-bold">
                        {segment.vlan}
                      </Badge>
                    </td>
                    <td className="p-4">
                      <div className="flex items-center gap-2 w-40">
                        <div className="flex-1 h-2 bg-muted rounded-full overflow-hidden">
                          <div
                            className={`h-full rounded-full ${segment.usagePercent > 80 ? "bg-amber-500" : "bg-primary"}`}
                            style={{ width: `${segment.usagePercent}%` }}
                          />
                        </div>
                        <span className="text-[10px] font-medium">
                          {segment.usedIps}/{segment.totalIps}
                        </span>
                      </div>
                    </td>
                    <td className="p-4">
                      <Badge variant={segment.status === "ONLINE" ? "success" : "warning"}>
                        {segment.status === "ONLINE" ? "Online" : "Degradado"}
                      </Badge>
                    </td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8 text-muted-foreground hover:text-primary"
                          onClick={() => openEditSegment(segment)}
                        >
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8 text-destructive hover:text-destructive"
                          onClick={() => handleDeleteSegment(segment.id)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </CardContent>
      </Card>

      <Modal
        isOpen={isModalOpen}
        onClose={() => { setIsModalOpen(false); setEditingSegmentId(null) }}
        title={editingSegmentId ? "Editar VLAN" : "Nova VLAN"}
      >
        <form className="space-y-4" onSubmit={handleSaveSegment}>
          <div className="space-y-2">
            <label className="text-sm font-medium" htmlFor="segment-name">
              Nome
            </label>
            <Input
              id="segment-name"
              value={segmentForm.name}
              onChange={(e) => setSegmentForm((prev) => ({ ...prev, name: e.target.value }))}
              placeholder="VLAN 60 - Laboratorio"
              required
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="space-y-2">
              <label className="text-sm font-medium" htmlFor="segment-gateway">
                Gateway
              </label>
              <Input
                id="segment-gateway"
                value={segmentForm.gateway}
                onChange={(e) => setSegmentForm((prev) => ({ ...prev, gateway: e.target.value }))}
                placeholder="10.0.60.1"
                required
              />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium" htmlFor="segment-vlan">
                VLAN
              </label>
              <Input
                id="segment-vlan"
                value={segmentForm.vlan}
                onChange={(e) => setSegmentForm((prev) => ({ ...prev, vlan: e.target.value }))}
                placeholder="60"
                required
              />
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="space-y-2">
              <label className="text-sm font-medium" htmlFor="segment-cidr">
                CIDR
              </label>
              <Input
                id="segment-cidr"
                value={segmentForm.cidr}
                onChange={(e) => setSegmentForm((prev) => ({ ...prev, cidr: e.target.value }))}
                placeholder="10.0.60.0/24"
                required
              />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium" htmlFor="segment-total-ips">
                Total de IPs
              </label>
              <Input
                id="segment-total-ips"
                type="number"
                min={1}
                value={segmentForm.totalIps}
                onChange={(e) =>
                  setSegmentForm((prev) => ({ ...prev, totalIps: Number(e.target.value) || 254 }))
                }
                required
              />
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => { setIsModalOpen(false); setEditingSegmentId(null) }}
              disabled={savingSegment}
            >
              Cancelar
            </Button>
            <Button type="submit" disabled={savingSegment}>
              {savingSegment ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Plus className="mr-2 h-4 w-4" />}
              {editingSegmentId ? "Salvar Alterações" : "Criar VLAN"}
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}

NOVAPRATA_EOF
mkdir -p "src/app/(dashboard)/settings"
cat > "src/app/(dashboard)/settings/page.tsx" << 'NOVAPRATA_EOF'
"use client"

import React from "react"
import { KeyRound, Loader2, ShieldCheck, User } from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

export default function SettingsPage() {
  const [form, setForm] = React.useState({ currentPassword: "", newPassword: "", confirmPassword: "" })
  const [loading, setLoading] = React.useState(false)
  const [message, setMessage] = React.useState<{ type: "success" | "error"; text: string } | null>(null)

  async function handleChangePassword(e: React.FormEvent) {
    e.preventDefault()
    setMessage(null)

    if (form.newPassword !== form.confirmPassword) {
      setMessage({ type: "error", text: "A confirmação não confere com a nova senha." })
      return
    }

    setLoading(true)
    try {
      const res = await fetch("/api/auth/change-password", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          currentPassword: form.currentPassword,
          newPassword: form.newPassword,
        }),
      })
      const data = await res.json().catch(() => ({}))
      if (!res.ok) {
        throw new Error(data.error || "Erro ao trocar senha")
      }
      setMessage({ type: "success", text: "Senha atualizada com sucesso." })
      setForm({ currentPassword: "", newPassword: "", confirmPassword: "" })
    } catch (err) {
      setMessage({ type: "error", text: err instanceof Error ? err.message : "Erro inesperado" })
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Configurações</h1>
        <p className="text-muted-foreground">Ajustes gerais da plataforma e preferências de uso.</p>
      </div>

      <Card className="max-w-xl">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <KeyRound className="h-5 w-5 text-primary" /> Trocar Senha
          </CardTitle>
          <CardDescription>Atualize sua própria senha de acesso ao sistema.</CardDescription>
        </CardHeader>
        <CardContent>
          {message && (
            <div
              className={
                message.type === "success"
                  ? "mb-4 p-3 rounded-md bg-emerald-500/10 border border-emerald-500/20 text-sm text-emerald-500"
                  : "mb-4 p-3 rounded-md bg-red-500/10 border border-red-500/20 text-sm text-red-500"
              }
            >
              {message.text}
            </div>
          )}
          <form onSubmit={handleChangePassword} className="space-y-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">Senha atual</label>
              <Input
                type="password"
                required
                value={form.currentPassword}
                onChange={e => setForm({ ...form, currentPassword: e.target.value })}
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Nova senha</label>
                <Input
                  type="password"
                  required
                  minLength={6}
                  value={form.newPassword}
                  onChange={e => setForm({ ...form, newPassword: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Confirmar nova senha</label>
                <Input
                  type="password"
                  required
                  minLength={6}
                  value={form.confirmPassword}
                  onChange={e => setForm({ ...form, confirmPassword: e.target.value })}
                />
              </div>
            </div>
            <div className="flex justify-end pt-2">
              <Button type="submit" disabled={loading}>
                {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <ShieldCheck className="mr-2 h-4 w-4" />}
                Atualizar Senha
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      <Card className="max-w-xl">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <User className="h-5 w-5 text-muted-foreground" /> Mais Configurações
          </CardTitle>
          <CardDescription>
            Preferências de notificação, tema padrão e integrações ficam aqui conforme forem implementadas.
          </CardDescription>
        </CardHeader>
      </Card>
    </div>
  )
}

NOVAPRATA_EOF
mkdir -p "src/app/(dashboard)/suppliers"
cat > "src/app/(dashboard)/suppliers/page.tsx" << 'NOVAPRATA_EOF'
"use client"

import React from "react"
import { Building2, Phone, Mail, Plus, Loader2, Pencil, Trash2, RefreshCw } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { SupplierForm } from "@/components/features/suppliers/SupplierForm"
import { useConfirm } from "@/components/confirm-dialog-provider"
import { useToast } from "@/components/toast-provider"

export default function SuppliersPage() {
  const confirmDialog = useConfirm()
  const { success, error: toastError } = useToast()
  const [suppliers, setSuppliers] = React.useState<any[]>([])
  const [loading, setLoading] = React.useState(true)
  const [isModalOpen, setIsModalOpen] = React.useState(false)
  const [editingSupplier, setEditingSupplier] = React.useState<any>(null)

  const fetchData = React.useCallback(async () => {
    setLoading(true)
    try {
      const res = await fetch("/api/suppliers")
      const data = await res.json()
      if (Array.isArray(data)) setSuppliers(data)
    } catch (error) {
      console.error("Error fetching suppliers:", error)
    } finally {
      setLoading(false)
    }
  }, [])

  React.useEffect(() => { fetchData() }, [fetchData])

  async function handleCreateOrUpdate(data: any) {
    const url = editingSupplier ? `/api/suppliers/${editingSupplier.id}` : "/api/suppliers"
    const method = editingSupplier ? "PUT" : "POST"
    try {
      const res = await fetch(url, {
        method,
        body: JSON.stringify(data),
        headers: { "Content-Type": "application/json" },
      })
      if (res.ok) {
        setIsModalOpen(false)
        setEditingSupplier(null)
        success(editingSupplier ? "Fornecedor atualizado" : "Fornecedor cadastrado")
        fetchData()
      } else {
        toastError("Erro ao salvar fornecedor")
      }
    } catch (error) {
      console.error("Error saving supplier:", error)
      toastError("Erro ao salvar fornecedor")
    }
  }

  async function handleDelete(id: string) {
    const ok = await confirmDialog({ title: "Excluir fornecedor", message: "Deseja realmente excluir este fornecedor? Essa ação não pode ser desfeita.", destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/suppliers/${id}`, { method: "DELETE" })
      if (res.ok) {
        success("Fornecedor excluído")
        fetchData()
      } else {
        toastError("Erro ao excluir fornecedor")
      }
    } catch (error) {
      console.error("Error deleting supplier:", error)
      toastError("Erro ao excluir fornecedor")
    }
  }

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Fornecedores</h1>
          <p className="text-muted-foreground">Contatos de suporte e contratos por tipo de serviço.</p>
        </div>
        <Button className="bg-primary shadow-lg shadow-primary/20" onClick={() => { setEditingSupplier(null); setIsModalOpen(true) }}>
          <Plus className="mr-2 h-4 w-4" />
          Novo Fornecedor
        </Button>
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Lista de Fornecedores</CardTitle>
            <CardDescription>Quem resolve cada tipo de problema.</CardDescription>
          </div>
          <Button variant="outline" size="sm" onClick={fetchData} disabled={loading}>
            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="mr-2 h-4 w-4" />}
            Sincronizar
          </Button>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y relative min-h-[300px]">
            {loading ? (
              <div className="absolute inset-0 flex items-center justify-center bg-background/50 backdrop-blur-[1px]">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
              </div>
            ) : suppliers.length === 0 ? (
              <div className="p-12 text-center text-muted-foreground">Nenhum fornecedor cadastrado.</div>
            ) : (
              suppliers.map((s) => (
                <div key={s.id} className="p-4 hover:bg-muted/50 transition-colors flex items-center justify-between group">
                  <div className="flex items-center gap-4">
                    <div className="p-2 rounded-full bg-primary/10 text-primary">
                      <Building2 className="h-5 w-5" />
                    </div>
                    <div>
                      <div className="flex items-center gap-2 flex-wrap">
                        <p className="font-semibold text-sm">{s.name}</p>
                        <Badge variant="outline" className="text-[10px] font-normal py-0 h-4">{s.serviceType}</Badge>
                        {s.hasContract && (
                          <Badge className="text-[10px] font-normal py-0 h-4 bg-emerald-500/10 text-emerald-500 border-emerald-500/20 border">
                            Com contrato
                          </Badge>
                        )}
                      </div>
                      <p className="text-xs text-muted-foreground mt-1 flex items-center gap-3">
                        {s.contactName && <span>{s.contactName}</span>}
                        {s.phone && <span className="flex items-center gap-1"><Phone className="h-3 w-3" />{s.phone}</span>}
                        {s.email && <span className="flex items-center gap-1"><Mail className="h-3 w-3" />{s.email}</span>}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Button variant="ghost" size="icon" className="h-8 w-8 text-muted-foreground hover:text-primary" onClick={() => { setEditingSupplier(s); setIsModalOpen(true) }}>
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <Button variant="ghost" size="icon" className="h-8 w-8 text-destructive hover:text-destructive" onClick={() => handleDelete(s.id)}>
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              ))
            )}
          </div>
        </CardContent>
      </Card>

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingSupplier ? "Editar Fornecedor" : "Novo Fornecedor"}>
        <SupplierForm
          initialData={editingSupplier}
          onCancel={() => setIsModalOpen(false)}
          onSubmit={handleCreateOrUpdate}
        />
      </Modal>
    </div>
  )
}

NOVAPRATA_EOF
mkdir -p "src/app/(dashboard)/tickets"
cat > "src/app/(dashboard)/tickets/page.tsx" << 'NOVAPRATA_EOF'
"use client"

import React from "react"
import {
  Ticket as TicketIcon,
  Clock,
  CheckCircle2,
  AlertTriangle,
  Plus,
  Loader2,
  Pencil,
  Trash2,
  RefreshCw,
} from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { cn } from "@/lib/utils"
import { getSlaStatus } from "@/lib/sla"
import { useConfirm } from "@/components/confirm-dialog-provider"
import { useToast } from "@/components/toast-provider"
import { TicketForm } from "@/components/features/tickets/TicketForm"

const PRIORITY_STYLE: Record<string, string> = {
  BAIXA: "bg-zinc-500/10 text-zinc-400 border-zinc-500/20",
  MEDIA: "bg-blue-500/10 text-blue-500 border-blue-500/20",
  ALTA: "bg-amber-500/10 text-amber-500 border-amber-500/20",
  CRITICA: "bg-red-500/10 text-red-500 border-red-500/20",
}

export default function TicketsPage() {
  const confirmDialog = useConfirm()
  const { success, error: toastError } = useToast()
  const [tickets, setTickets] = React.useState<any[]>([])
  const [assets, setAssets] = React.useState<any[]>([])
  const [loading, setLoading] = React.useState(true)
  const [isModalOpen, setIsModalOpen] = React.useState(false)
  const [editingTicket, setEditingTicket] = React.useState<any>(null)

  const fetchData = React.useCallback(async () => {
    setLoading(true)
    try {
      const [tRes, aRes] = await Promise.all([
        fetch("/api/tickets"),
        fetch("/api/assets"),
      ])
      const tData = await tRes.json()
      const aData = await aRes.json()
      if (Array.isArray(tData)) setTickets(tData)
      if (Array.isArray(aData)) setAssets(aData)
    } catch (error) {
      console.error("Error fetching tickets:", error)
    } finally {
      setLoading(false)
    }
  }, [])

  React.useEffect(() => { fetchData() }, [fetchData])

  async function handleCreateOrUpdate(data: any) {
    const url = editingTicket ? `/api/tickets/${editingTicket.id}` : "/api/tickets"
    const method = editingTicket ? "PUT" : "POST"
    try {
      const res = await fetch(url, {
        method,
        body: JSON.stringify(data),
        headers: { "Content-Type": "application/json" },
      })
      if (res.ok) {
        setIsModalOpen(false)
        setEditingTicket(null)
        success(editingTicket ? "Chamado atualizado" : "Chamado aberto")
        fetchData()
      } else {
        toastError("Erro ao salvar chamado")
      }
    } catch (error) {
      console.error("Error saving ticket:", error)
      toastError("Erro ao salvar chamado")
    }
  }

  async function handleDelete(id: string) {
    const ok = await confirmDialog({ title: "Excluir chamado", message: "Deseja realmente excluir este chamado? Essa ação não pode ser desfeita.", destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/tickets/${id}`, { method: "DELETE" })
      if (res.ok) {
        success("Chamado excluído")
        fetchData()
      } else {
        toastError("Erro ao excluir chamado")
      }
    } catch (error) {
      console.error("Error deleting ticket:", error)
      toastError("Erro ao excluir chamado")
    }
  }

  const openCount = tickets.filter(t => t.status !== "CONCLUIDO").length
  const criticalOpenCount = tickets.filter(t => t.status !== "CONCLUIDO" && t.priority === "CRITICA").length
  const closedCount = tickets.filter(t => t.status === "CONCLUIDO").length
  const slaBreachedCount = tickets.filter(t => !getSlaStatus(t).isResolved && getSlaStatus(t).isBreached).length

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Chamados</h1>
          <p className="text-muted-foreground">Suporte interno: internet, sistema, balança, impressora, acesso e mais.</p>
        </div>
        <Button className="bg-primary shadow-lg shadow-primary/20" onClick={() => { setEditingTicket(null); setIsModalOpen(true) }}>
          <Plus className="mr-2 h-4 w-4" />
          Abrir Chamado
        </Button>
      </div>

      <div className="grid gap-6 md:grid-cols-4">
        <Card className="bg-amber-500/5 border-amber-500/20">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Clock className="h-4 w-4 text-amber-500" /> Chamados em Aberto
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{String(openCount).padStart(2, '0')}</div>
          </CardContent>
        </Card>
        <Card className="bg-red-500/5 border-red-500/20">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <AlertTriangle className="h-4 w-4 text-red-500" /> Críticos em Aberto
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{String(criticalOpenCount).padStart(2, '0')}</div>
          </CardContent>
        </Card>
        <Card className="bg-emerald-500/5 border-emerald-500/20">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <CheckCircle2 className="h-4 w-4 text-emerald-500" /> Resolvidos
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{String(closedCount).padStart(2, '0')}</div>
          </CardContent>
        </Card>
        <Card className="bg-rose-500/5 border-rose-500/20">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <AlertTriangle className="h-4 w-4 text-rose-500" /> SLA Estourado
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{String(slaBreachedCount).padStart(2, '0')}</div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Lista de Chamados</CardTitle>
            <CardDescription>Todos os chamados registrados no sistema.</CardDescription>
          </div>
          <Button variant="outline" size="sm" onClick={fetchData} disabled={loading}>
            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="mr-2 h-4 w-4" />}
            Sincronizar
          </Button>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y relative min-h-[300px]">
            {loading ? (
              <div className="absolute inset-0 flex items-center justify-center bg-background/50 backdrop-blur-[1px]">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
              </div>
            ) : tickets.length === 0 ? (
              <div className="p-12 text-center text-muted-foreground">
                Nenhum chamado registrado ainda.
              </div>
            ) : (
              tickets.map((t) => (
                <div key={t.id} className="p-4 hover:bg-muted/50 transition-colors flex items-center justify-between group">
                  <div className="flex items-center gap-4">
                    <div className={cn(
                      "p-2 rounded-full",
                      t.status === "CONCLUIDO" ? "bg-emerald-500/10 text-emerald-500" : "bg-amber-500/10 text-amber-500"
                    )}>
                      {t.status === "CONCLUIDO" ? <CheckCircle2 className="h-5 w-5" /> : <TicketIcon className="h-5 w-5" />}
                    </div>
                    <div>
                      <div className="flex items-center gap-2 flex-wrap">
                        <p className="font-semibold text-sm">{t.category}</p>
                        <span className="text-muted-foreground opacity-30">•</span>
                        <p className="text-sm text-muted-foreground">{t.sector}</p>
                        <Badge className={cn("text-[10px] font-normal py-0 h-4 border", PRIORITY_STYLE[t.priority])}>
                          {t.priority}
                        </Badge>
                        <Badge variant="outline" className="text-[10px] font-normal py-0 h-4">{t.status}</Badge>
                        {t.recurring && (
                          <Badge variant="outline" className="text-[10px] font-normal py-0 h-4 text-red-400 border-red-500/30">
                            Recorrente
                          </Badge>
                        )}
                        {(() => {
                          const sla = getSlaStatus(t)
                          return (
                            <Badge
                              className={cn(
                                "text-[10px] font-normal py-0 h-4 border",
                                sla.isResolved
                                  ? sla.isBreached
                                    ? "bg-zinc-500/10 text-zinc-400 border-zinc-500/20"
                                    : "bg-emerald-500/10 text-emerald-500 border-emerald-500/20"
                                  : sla.isBreached
                                  ? "bg-red-500/10 text-red-500 border-red-500/20"
                                  : "bg-blue-500/10 text-blue-500 border-blue-500/20"
                              )}
                            >
                              SLA: {sla.label}
                            </Badge>
                          )
                        })()}
                      </div>
                      <p className="text-xs text-muted-foreground mt-1 max-w-xl truncate">
                        {t.description} — aberto por {t.requesterName} em {new Date(t.openedAt).toLocaleDateString()}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 text-muted-foreground hover:text-primary"
                      onClick={() => { setEditingTicket(t); setIsModalOpen(true) }}
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 text-destructive hover:text-destructive"
                      onClick={() => handleDelete(t.id)}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              ))
            )}
          </div>
        </CardContent>
      </Card>

      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingTicket ? "Editar Chamado" : "Novo Chamado"}
      >
        <TicketForm
          initialData={editingTicket}
          assets={assets}
          onCancel={() => setIsModalOpen(false)}
          onSubmit={handleCreateOrUpdate}
        />
      </Modal>
    </div>
  )
}

NOVAPRATA_EOF
mkdir -p "src/app/(dashboard)/vault"
cat > "src/app/(dashboard)/vault/page.tsx" << 'NOVAPRATA_EOF'
"use client"

import React from "react"
import {
  Lock,
  Shield,
  Eye,
  EyeOff,
  Copy,
  Search,
  Key,
  Pencil,
  Trash2,
  AlertTriangle,
  Loader2,
  Plus,
} from "lucide-react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { useConfirm } from "@/components/confirm-dialog-provider"
import { useToast } from "@/components/toast-provider"

type VaultCredential = {
  id: string
  title: string
  username: string
  type: string
  assetId: string | null
  assetLabel: string
  lastUsedAt: string | null
  lastRotatedAt: string | null
  isStale: boolean
}

type VaultStats = {
  totalCredentials: number
  staleCredentials: number
  recentViews: number
  rotationLimitDays: number
}

type AssetOption = {
  id: string
  name: string
  tag: string
}

const initialCredentialForm = {
  title: "",
  username: "",
  password: "",
  type: "OTHER",
  assetId: "",
}

function formatLastUsed(date: string | null) {
  if (!date) return "Nunca utilizado"
  return new Date(date).toLocaleString("pt-BR")
}

export default function VaultPage() {
  const confirmDialog = useConfirm()
  const { success, error: toastError } = useToast()
  const [stats, setStats] = React.useState<VaultStats | null>(null)
  const [credentials, setCredentials] = React.useState<VaultCredential[]>([])
  const [assets, setAssets] = React.useState<AssetOption[]>([])
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState<string | null>(null)
  const [searchTerm, setSearchTerm] = React.useState("")
  const [revealed, setRevealed] = React.useState<Record<string, string>>({})
  const [revealingId, setRevealingId] = React.useState<string | null>(null)
  const [isModalOpen, setIsModalOpen] = React.useState(false)
  const [savingCredential, setSavingCredential] = React.useState(false)
  const [credentialForm, setCredentialForm] = React.useState(initialCredentialForm)
  const [editingCredentialId, setEditingCredentialId] = React.useState<string | null>(null)

  const fetchData = React.useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const [vaultRes, assetsRes] = await Promise.all([
        fetch("/api/vault/credentials"),
        fetch("/api/assets"),
      ])

      const vaultData = (await vaultRes.json().catch(() => ({}))) as {
        error?: string
        stats?: VaultStats
        credentials?: VaultCredential[]
      }

      const assetsData = (await assetsRes.json().catch(() => [])) as Array<{
        id: string
        name: string
        tag: string
      }>

      if (!vaultRes.ok) {
        throw new Error(vaultData.error || "Falha ao carregar cofre")
      }

      setStats(vaultData.stats || null)
      setCredentials(vaultData.credentials || [])
      setAssets(Array.isArray(assetsData) ? assetsData : [])
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro inesperado")
    } finally {
      setLoading(false)
    }
  }, [])

  React.useEffect(() => {
    fetchData()
  }, [fetchData])

  const filteredCredentials = credentials.filter((credential) => {
    const term = searchTerm.toLowerCase()
    return (
      credential.title.toLowerCase().includes(term) ||
      credential.username.toLowerCase().includes(term) ||
      credential.assetLabel.toLowerCase().includes(term) ||
      credential.type.toLowerCase().includes(term)
    )
  })

  async function revealCredential(id: string, mode: "VIEW" | "COPY") {
    setRevealingId(id)
    try {
      const res = await fetch(`/api/vault/credentials/${id}/reveal`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ mode }),
      })

      const data = (await res.json().catch(() => ({}))) as { error?: string; password?: string }
      if (!res.ok || !data.password) {
        throw new Error(data.error || "Falha ao revelar credencial")
      }

      setRevealed((prev) => ({ ...prev, [id]: data.password as string }))
      if (mode === "COPY" && navigator?.clipboard?.writeText) {
        await navigator.clipboard.writeText(data.password)
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro inesperado")
    } finally {
      setRevealingId(null)
    }
  }

  function hideCredential(id: string) {
    setRevealed((prev) => {
      const next = { ...prev }
      delete next[id]
      return next
    })
  }

  async function saveCredential(e: React.FormEvent) {
    e.preventDefault()
    setSavingCredential(true)
    try {
      const url = editingCredentialId ? `/api/vault/credentials/${editingCredentialId}` : "/api/vault/credentials"
      const method = editingCredentialId ? "PUT" : "POST"
      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: credentialForm.title,
          username: credentialForm.username,
          password: credentialForm.password,
          type: credentialForm.type,
          assetId: credentialForm.assetId || null,
        }),
      })

      const data = (await res.json().catch(() => ({}))) as { error?: string }
      if (!res.ok) {
        throw new Error(data.error || "Falha ao salvar credencial")
      }

      setCredentialForm(initialCredentialForm)
      setEditingCredentialId(null)
      setIsModalOpen(false)
      success(editingCredentialId ? "Credencial atualizada" : "Credencial salva")
      await fetchData()
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro inesperado")
      toastError(err instanceof Error ? err.message : "Erro inesperado")
    } finally {
      setSavingCredential(false)
    }
  }

  function openEditCredential(credential: VaultCredential) {
    setEditingCredentialId(credential.id)
    setCredentialForm({
      title: credential.title,
      username: credential.username,
      password: "",
      type: credential.type,
      assetId: credential.assetId || "",
    })
    setIsModalOpen(true)
  }

  function openNewCredential() {
    setEditingCredentialId(null)
    setCredentialForm(initialCredentialForm)
    setIsModalOpen(true)
  }

  async function handleDeleteCredential(id: string) {
    const ok = await confirmDialog({ title: "Excluir credencial", message: "Deseja realmente excluir esta credencial? Essa ação não pode ser desfeita.", destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/vault/credentials/${id}`, { method: "DELETE" })
      const data = (await res.json().catch(() => ({}))) as { error?: string }
      if (!res.ok) {
        throw new Error(data.error || "Erro ao excluir credencial")
      }
      success("Credencial excluída")
      await fetchData()
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro inesperado")
      toastError(err instanceof Error ? err.message : "Erro inesperado")
    }
  }

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Cofre de Credenciais</h1>
          <p className="text-muted-foreground">Armazenamento seguro com auditoria de visualizacao e copia.</p>
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          <Badge variant="outline" className="h-10 px-3 border-amber-500/50 text-amber-500 bg-amber-500/5">
            <AlertTriangle className="mr-2 h-4 w-4" />
            {stats?.staleCredentials ?? 0} senhas sem rotacao recente
          </Badge>
          <Button className="bg-primary" onClick={openNewCredential}>
            <Plus className="mr-2 h-4 w-4" />
            Nova Credencial
          </Button>
        </div>
      </div>

      {error && (
        <Card className="border-destructive/30 bg-destructive/5">
          <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
        </Card>
      )}

      <Card className="bg-primary/5 border-primary/20">
        <CardContent className="p-4 flex items-center gap-4">
          <div className="p-3 bg-primary/10 rounded-full">
            <Shield className="h-6 w-6 text-primary" />
          </div>
          <div>
            <p className="font-semibold text-primary">Seguranca Ativa</p>
            <p className="text-sm text-primary/80">
              {stats?.recentViews ?? 0} acessos auditados nas ultimas 24h.
            </p>
          </div>
        </CardContent>
      </Card>

      <div className="relative w-full">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Buscar credencial por nome, usuario ou ativo..."
          className="pl-10 h-11"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {loading ? (
          <Card className="md:col-span-2 lg:col-span-3">
            <CardContent className="p-8 text-center">
              <Loader2 className="h-8 w-8 animate-spin mx-auto text-primary" />
            </CardContent>
          </Card>
        ) : filteredCredentials.length === 0 ? (
          <Card className="md:col-span-2 lg:col-span-3">
            <CardContent className="p-8 text-center text-muted-foreground">
              Nenhuma credencial encontrada.
            </CardContent>
          </Card>
        ) : (
          filteredCredentials.map((credential) => {
            const currentSecret = revealed[credential.id]
            const isRevealed = typeof currentSecret === "string"
            const isPendingReveal = revealingId === credential.id

            return (
              <Card key={credential.id} className="overflow-hidden group hover:border-primary/50 transition-all">
                <CardHeader className="pb-3 flex flex-row items-start justify-between space-y-0">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-muted rounded-lg group-hover:bg-primary/10 group-hover:text-primary transition-colors">
                      <Key className="h-5 w-5" />
                    </div>
                    <div>
                      <CardTitle className="text-base">{credential.title}</CardTitle>
                      <CardDescription className="text-xs">{credential.assetLabel}</CardDescription>
                    </div>
                  </div>
                  <div className="flex items-center gap-1">
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 text-muted-foreground hover:text-primary"
                      onClick={() => openEditCredential(credential)}
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 text-destructive hover:text-destructive"
                      onClick={() => handleDeleteCredential(credential.id)}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-1.5">
                    <p className="text-[10px] uppercase font-bold text-muted-foreground">Usuario</p>
                    <div className="flex items-center justify-between bg-muted/30 p-2 rounded border border-transparent hover:border-muted font-mono text-sm">
                      <span>{credential.username}</span>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-6 w-6"
                        onClick={() => revealCredential(credential.id, "COPY")}
                        disabled={isPendingReveal}
                      >
                        {isPendingReveal ? <Loader2 className="h-3 w-3 animate-spin" /> : <Copy className="h-3 w-3" />}
                      </Button>
                    </div>
                  </div>
                  <div className="space-y-1.5">
                    <p className="text-[10px] uppercase font-bold text-muted-foreground">Senha</p>
                    <div className="flex items-center justify-between bg-zinc-950 text-zinc-100 p-2 rounded font-mono text-sm">
                      <span>{isRevealed ? currentSecret : "••••••••••••••••"}</span>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-6 w-6 hover:bg-zinc-800"
                        onClick={() => (isRevealed ? hideCredential(credential.id) : revealCredential(credential.id, "VIEW"))}
                        disabled={isPendingReveal}
                      >
                        {isPendingReveal ? (
                          <Loader2 className="h-3 w-3 animate-spin" />
                        ) : isRevealed ? (
                          <EyeOff className="h-3 w-3" />
                        ) : (
                          <Eye className="h-3 w-3" />
                        )}
                      </Button>
                    </div>
                  </div>
                </CardContent>
                <div className="px-6 py-3 bg-muted/30 border-t flex items-center justify-between">
                  <span className="text-[10px] text-muted-foreground">Ultimo uso: {formatLastUsed(credential.lastUsedAt)}</span>
                  <Badge variant={credential.isStale ? "warning" : "secondary"} className="text-[10px] uppercase">
                    {credential.type}
                  </Badge>
                </div>
              </Card>
            )
          })
        )}
      </div>

      <Modal
        isOpen={isModalOpen}
        onClose={() => { setIsModalOpen(false); setEditingCredentialId(null) }}
        title={editingCredentialId ? "Editar Credencial" : "Nova Credencial"}
      >
        <form className="space-y-4" onSubmit={saveCredential}>
          <div className="space-y-2">
            <label className="text-sm font-medium" htmlFor="vault-title">
              Nome da credencial
            </label>
            <Input
              id="vault-title"
              value={credentialForm.title}
              onChange={(e) => setCredentialForm((prev) => ({ ...prev, title: e.target.value }))}
              placeholder="Painel AWS TI"
              required
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="space-y-2">
              <label className="text-sm font-medium" htmlFor="vault-username">
                Usuario
              </label>
              <Input
                id="vault-username"
                value={credentialForm.username}
                onChange={(e) => setCredentialForm((prev) => ({ ...prev, username: e.target.value }))}
                placeholder="admin_cloud"
                required
              />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium" htmlFor="vault-type">
                Tipo
              </label>
              <select
                id="vault-type"
                className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                value={credentialForm.type}
                onChange={(e) => setCredentialForm((prev) => ({ ...prev, type: e.target.value }))}
              >
                <option value="SERVER">SERVER</option>
                <option value="NETWORK">NETWORK</option>
                <option value="WIFI">WIFI</option>
                <option value="CLOUD">CLOUD</option>
                <option value="APP">APP</option>
                <option value="OTHER">OTHER</option>
              </select>
            </div>
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium" htmlFor="vault-password">
              Senha {editingCredentialId && <span className="text-muted-foreground font-normal">(deixe em branco para manter a atual)</span>}
            </label>
            <Input
              id="vault-password"
              type="password"
              value={credentialForm.password}
              onChange={(e) => setCredentialForm((prev) => ({ ...prev, password: e.target.value }))}
              placeholder={editingCredentialId ? "Nova senha (opcional)" : "Senha forte"}
              required={!editingCredentialId}
            />
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium" htmlFor="vault-asset">
              Ativo relacionado
            </label>
            <select
              id="vault-asset"
              className="h-10 w-full rounded-md border bg-background px-3 text-sm"
              value={credentialForm.assetId}
              onChange={(e) => setCredentialForm((prev) => ({ ...prev, assetId: e.target.value }))}
            >
              <option value="">Sem ativo</option>
              {assets.map((asset) => (
                <option key={asset.id} value={asset.id}>
                  {asset.tag} - {asset.name}
                </option>
              ))}
            </select>
          </div>

          <div className="flex justify-end gap-2 pt-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => { setIsModalOpen(false); setEditingCredentialId(null) }}
              disabled={savingCredential}
            >
              Cancelar
            </Button>
            <Button type="submit" disabled={savingCredential}>
              {savingCredential ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Lock className="mr-2 h-4 w-4" />}
              {editingCredentialId ? "Salvar Alterações" : "Salvar credencial"}
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}

NOVAPRATA_EOF
mkdir -p "src/app/api/auth/change-password"
cat > "src/app/api/auth/change-password/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import bcrypt from "bcryptjs"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function PUT(request: Request) {
  const session = await getSession()
  if (!session || typeof session.userId !== "string") {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const body = await request.json()
    const currentPassword = typeof body.currentPassword === "string" ? body.currentPassword : ""
    const newPassword = typeof body.newPassword === "string" ? body.newPassword : ""

    if (!currentPassword || !newPassword) {
      return NextResponse.json({ error: "Preencha a senha atual e a nova senha" }, { status: 400 })
    }
    if (newPassword.length < 6) {
      return NextResponse.json({ error: "A nova senha precisa ter pelo menos 6 caracteres" }, { status: 400 })
    }

    const user = await prisma.user.findUnique({ where: { id: session.userId } })
    if (!user) {
      return NextResponse.json({ error: "Usuário não encontrado" }, { status: 404 })
    }

    const isValid = await bcrypt.compare(currentPassword, user.password)
    if (!isValid) {
      return NextResponse.json({ error: "Senha atual incorreta" }, { status: 401 })
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10)
    await prisma.user.update({
      where: { id: user.id },
      data: { password: hashedPassword },
    })

    return NextResponse.json({ message: "Senha atualizada com sucesso" })
  } catch (error) {
    console.error("Change Password Error:", error)
    return NextResponse.json({ error: "Erro ao trocar senha" }, { status: 500 })
  }
}

NOVAPRATA_EOF
mkdir -p "src/app/api/employees/[id]"
cat > "src/app/api/employees/[id]/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"
import bcrypt from "bcryptjs"

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
    const { name, email, role, phone, department, jobTitle, status, newPassword } = body

    const data: any = {
      name,
      email,
      role,
      phone: phone || null,
      department: department || null,
      jobTitle: jobTitle || null,
      status: status || "ATIVO",
    }

    // Admin define uma senha nova pro colaborador (só se o campo foi preenchido)
    if (typeof newPassword === "string" && newPassword.trim().length > 0) {
      if (newPassword.trim().length < 6) {
        return NextResponse.json({ error: "A nova senha precisa ter pelo menos 6 caracteres" }, { status: 400 })
      }
      data.password = await bcrypt.hash(newPassword.trim(), 10)
    }

    const user = await prisma.user.update({
      where: { id },
      data,
    })

    return NextResponse.json({ ...user, password: undefined })
  } catch (error: any) {
    if (error?.code === "P2002") {
      return NextResponse.json({ error: "Já existe um colaborador com esse e-mail" }, { status: 409 })
    }
    console.error("Error updating employee:", error)
    return NextResponse.json({ error: "Erro ao atualizar colaborador" }, { status: 500 })
  }
}

export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params

    const assetsCount = await prisma.asset.count({ where: { userId: id } })
    if (assetsCount > 0) {
      return NextResponse.json(
        { error: `Este colaborador tem ${assetsCount} ativo(s) vinculado(s). Reatribua os ativos antes de excluir.` },
        { status: 409 }
      )
    }

    await prisma.user.delete({ where: { id } })
    return NextResponse.json({ message: "Colaborador removido com sucesso" })
  } catch (error) {
    console.error("Error deleting employee:", error)
    return NextResponse.json({ error: "Erro ao excluir colaborador" }, { status: 500 })
  }
}

NOVAPRATA_EOF
mkdir -p "src/app/api/network/segments/[id]"
cat > "src/app/api/network/segments/[id]/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

function isValidIpv4(ip: string) {
  const parts = ip.split(".")
  if (parts.length !== 4) return false
  return parts.every((part) => {
    const n = Number(part)
    return !Number.isNaN(n) && n >= 0 && n <= 255
  })
}

function isValidCidr(cidr: string) {
  const [ip, bitsRaw] = cidr.split("/")
  const bits = Number(bitsRaw)
  return isValidIpv4(ip) && Number.isInteger(bits) && bits >= 8 && bits <= 30
}

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Nao autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    const body = await request.json()
    const name = typeof body.name === "string" ? body.name.trim() : ""
    const gateway = typeof body.gateway === "string" ? body.gateway.trim() : ""
    const vlan = typeof body.vlan === "string" ? body.vlan.trim() : ""
    const cidr = typeof body.cidr === "string" ? body.cidr.trim() : ""
    const totalIps = Number.isInteger(body.totalIps) && body.totalIps > 0 ? body.totalIps : 254
    const status = typeof body.status === "string" && body.status.trim() ? body.status.trim().toUpperCase() : "ONLINE"
    const notes = typeof body.notes === "string" && body.notes.trim().length > 0 ? body.notes.trim() : null

    if (!name || !gateway || !vlan || !cidr) {
      return NextResponse.json({ error: "Campos obrigatorios: name, gateway, vlan, cidr" }, { status: 400 })
    }
    if (!isValidIpv4(gateway)) {
      return NextResponse.json({ error: "Gateway invalido" }, { status: 400 })
    }
    if (!isValidCidr(cidr)) {
      return NextResponse.json({ error: "CIDR invalido. Exemplo: 10.0.10.0/24" }, { status: 400 })
    }

    const updated = await prisma.networkSegment.update({
      where: { id },
      data: { name, gateway, vlan, cidr, totalIps, status, notes },
    })

    return NextResponse.json(updated)
  } catch (error: any) {
    if (error?.code === "P2002") {
      return NextResponse.json({ error: "VLAN ou CIDR ja cadastrado" }, { status: 409 })
    }
    console.error("Update Network Segment Error:", error)
    return NextResponse.json({ error: "Erro ao atualizar segmento de rede" }, { status: 500 })
  }
}

export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Nao autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    await prisma.networkSegment.delete({ where: { id } })
    return NextResponse.json({ message: "Segmento removido com sucesso" })
  } catch (error) {
    console.error("Delete Network Segment Error:", error)
    return NextResponse.json({ error: "Erro ao excluir segmento de rede" }, { status: 500 })
  }
}

NOVAPRATA_EOF
mkdir -p "src/app/api/notifications"
cat > "src/app/api/notifications/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"
import { getSlaStatus } from "@/lib/sla"

export async function GET() {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const [openTickets, documents] = await Promise.all([
      prisma.ticket.findMany({
        where: { status: { not: "CONCLUIDO" } },
        select: { id: true, description: true, priority: true, status: true, openedAt: true, closedAt: true },
      }),
      prisma.document.findMany({
        select: { id: true, title: true, validUntil: true, type: true },
      }),
    ])

    const notifications: { id: string; type: "sla" | "document"; title: string; description: string; href: string; severity: "critical" | "warning" }[] = []

    for (const t of openTickets) {
      const sla = getSlaStatus(t)
      if (sla.isBreached) {
        notifications.push({
          id: `ticket-${t.id}`,
          type: "sla",
          title: "SLA estourado",
          description: t.description.slice(0, 70),
          href: "/tickets",
          severity: "critical",
        })
      }
    }

    const in15Days = new Date(Date.now() + 15 * 24 * 60 * 60 * 1000)
    for (const d of documents) {
      const validUntil = new Date(d.validUntil)
      if (validUntil < new Date()) {
        notifications.push({
          id: `doc-${d.id}`,
          type: "document",
          title: `${d.type === "CERTIFICADO" ? "Certificado" : "Licença"} vencido`,
          description: d.title,
          href: "/documents",
          severity: "critical",
        })
      } else if (validUntil <= in15Days) {
        notifications.push({
          id: `doc-${d.id}`,
          type: "document",
          title: `${d.type === "CERTIFICADO" ? "Certificado" : "Licença"} vencendo em breve`,
          description: d.title,
          href: "/documents",
          severity: "warning",
        })
      }
    }

    return NextResponse.json({ notifications, count: notifications.length })
  } catch (error) {
    console.error("Notifications Error:", error)
    return NextResponse.json({ error: "Erro ao carregar notificações" }, { status: 500 })
  }
}

NOVAPRATA_EOF
mkdir -p "src/app/api/search"
cat > "src/app/api/search/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function GET(request: Request) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  const { searchParams } = new URL(request.url)
  const q = (searchParams.get("q") || "").trim()

  if (q.length < 2) {
    return NextResponse.json({ results: [] })
  }

  try {
    const insensitive = { contains: q, mode: "insensitive" as const }

    const [assets, tickets, employees, suppliers, documents] = await Promise.all([
      prisma.asset.findMany({
        where: { OR: [{ name: insensitive }, { tag: insensitive }] },
        select: { id: true, name: true, tag: true },
        take: 5,
      }),
      prisma.ticket.findMany({
        where: { OR: [{ description: insensitive }, { category: insensitive }] },
        select: { id: true, description: true, category: true, status: true },
        take: 5,
      }),
      prisma.user.findMany({
        where: { OR: [{ name: insensitive }, { email: insensitive }] },
        select: { id: true, name: true, email: true },
        take: 5,
      }),
      prisma.supplier.findMany({
        where: { name: insensitive },
        select: { id: true, name: true, serviceType: true },
        take: 5,
      }),
      prisma.document.findMany({
        where: { OR: [{ title: insensitive }, { holder: insensitive }] },
        select: { id: true, title: true, type: true },
        take: 5,
      }),
    ])

    const results = [
      ...assets.map((a: any) => ({ type: "Ativo", id: a.id, label: a.name, sublabel: a.tag, href: `/assets/${a.id}` })),
      ...tickets.map((t: any) => ({ type: "Chamado", id: t.id, label: t.description.slice(0, 60), sublabel: `${t.category} · ${t.status}`, href: `/tickets` })),
      ...employees.map((e: any) => ({ type: "Colaborador", id: e.id, label: e.name, sublabel: e.email, href: `/employees` })),
      ...suppliers.map((s: any) => ({ type: "Fornecedor", id: s.id, label: s.name, sublabel: s.serviceType, href: `/suppliers` })),
      ...documents.map((d: any) => ({ type: "Certificado/Licença", id: d.id, label: d.title, sublabel: d.holder, href: `/documents` })),
    ]

    return NextResponse.json({ results })
  } catch (error) {
    console.error("Global Search Error:", error)
    return NextResponse.json({ error: "Erro na busca" }, { status: 500 })
  }
}

NOVAPRATA_EOF
mkdir -p "src/app/api/vault/credentials/[id]"
cat > "src/app/api/vault/credentials/[id]/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"
import { encryptVaultSecret } from "@/lib/vault-crypto"

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Nao autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    const body = (await request.json()) as {
      title?: string
      username?: string
      password?: string
      type?: string
      assetId?: string | null
    }

    const title = typeof body.title === "string" ? body.title.trim() : ""
    const username = typeof body.username === "string" ? body.username.trim() : ""
    const type = typeof body.type === "string" && body.type.trim() ? body.type.trim().toUpperCase() : "OTHER"
    const assetId = typeof body.assetId === "string" && body.assetId.trim() ? body.assetId.trim() : null
    const newPassword = typeof body.password === "string" ? body.password.trim() : ""

    if (!title || !username) {
      return NextResponse.json({ error: "Campos obrigatorios: title, username" }, { status: 400 })
    }

    const data: any = { title, username, type, assetId }

    // Só re-criptografa e marca rotação se uma nova senha foi de fato digitada
    if (newPassword) {
      data.passwordEncrypted = encryptVaultSecret(newPassword)
      data.lastRotatedAt = new Date()
    }

    const userId = typeof session.userId === "string" ? session.userId : null

    const updated = await prisma.$transaction(async (tx: any) => {
      const result = await tx.vaultCredential.update({ where: { id }, data })
      await tx.vaultAccessLog.create({
        data: {
          credentialId: id,
          userId,
          action: newPassword ? "ROTATE" : "UPDATE",
        },
      })
      return result
    })

    return NextResponse.json({
      id: updated.id,
      title: updated.title,
      username: updated.username,
      type: updated.type,
    })
  } catch (error: any) {
    if (error?.code === "P2002") {
      return NextResponse.json({ error: "Credencial com mesmo titulo e usuario ja existe" }, { status: 409 })
    }
    console.error("Vault Credential PUT Error:", error)
    return NextResponse.json({ error: "Erro ao atualizar credencial" }, { status: 500 })
  }
}

export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Nao autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    // Atencao: o log de acesso dessa credencial e apagado em cascata junto (onDelete: Cascade no schema).
    await prisma.vaultCredential.delete({ where: { id } })
    return NextResponse.json({ message: "Credencial removida com sucesso" })
  } catch (error) {
    console.error("Vault Credential DELETE Error:", error)
    return NextResponse.json({ error: "Erro ao excluir credencial" }, { status: 500 })
  }
}

NOVAPRATA_EOF
mkdir -p "src/app/api/vault/credentials"
cat > "src/app/api/vault/credentials/route.ts" << 'NOVAPRATA_EOF'
import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"
import { encryptVaultSecret } from "@/lib/vault-crypto"

const ROTATION_LIMIT_DAYS = 90

function getRotationDeadlineDate() {
  return new Date(Date.now() - ROTATION_LIMIT_DAYS * 24 * 60 * 60 * 1000)
}

export async function GET() {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Nao autorizado" }, { status: 401 })
  }

  try {
    const deadline = getRotationDeadlineDate()
    const [credentials, staleCount, recentViews] = await Promise.all([
      prisma.vaultCredential.findMany({
        orderBy: [{ updatedAt: "desc" }],
        include: {
          asset: {
            select: {
              id: true,
              name: true,
              tag: true,
            },
          },
        },
      }),
      prisma.vaultCredential.count({
        where: {
          OR: [{ lastRotatedAt: null }, { lastRotatedAt: { lt: deadline } }],
        },
      }),
      prisma.vaultAccessLog.count({
        where: {
          createdAt: {
            gte: new Date(Date.now() - 24 * 60 * 60 * 1000),
          },
          action: {
            in: ["VIEW", "COPY"],
          },
        },
      }),
    ])

    return NextResponse.json({
      stats: {
        totalCredentials: credentials.length,
        staleCredentials: staleCount,
        recentViews,
        rotationLimitDays: ROTATION_LIMIT_DAYS,
      },
      credentials: credentials.map((credential: any) => ({
        id: credential.id,
        title: credential.title,
        username: credential.username,
        type: credential.type,
        assetId: credential.assetId,
        assetLabel: credential.asset?.tag || credential.asset?.name || "Sem ativo",
        lastUsedAt: credential.lastUsedAt,
        lastRotatedAt: credential.lastRotatedAt,
        isStale: !credential.lastRotatedAt || credential.lastRotatedAt < deadline,
      })),
    })
  } catch (error) {
    console.error("Vault Credentials GET Error:", error)
    return NextResponse.json({ error: "Erro ao carregar cofre" }, { status: 500 })
  }
}

export async function POST(request: Request) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Nao autorizado" }, { status: 401 })
  }

  try {
    const body = (await request.json()) as {
      title?: string
      username?: string
      password?: string
      type?: string
      assetId?: string | null
    }

    const title = typeof body.title === "string" ? body.title.trim() : ""
    const username = typeof body.username === "string" ? body.username.trim() : ""
    const password = typeof body.password === "string" ? body.password : ""
    const type = typeof body.type === "string" && body.type.trim() ? body.type.trim().toUpperCase() : "OTHER"
    const assetId = typeof body.assetId === "string" && body.assetId.trim() ? body.assetId.trim() : null

    if (!title || !username || !password) {
      return NextResponse.json({ error: "Campos obrigatorios: title, username, password" }, { status: 400 })
    }

    const passwordEncrypted = encryptVaultSecret(password)

    const created = await prisma.vaultCredential.create({
      data: {
        title,
        username,
        passwordEncrypted,
        type,
        assetId,
        lastRotatedAt: new Date(),
      },
    })

    return NextResponse.json(
      {
        id: created.id,
        title: created.title,
        username: created.username,
        type: created.type,
      },
      { status: 201 }
    )
  } catch (error: unknown) {
    console.error("Vault Credentials POST Error:", error)
    if (
      typeof error === "object" &&
      error !== null &&
      "code" in error &&
      (error as { code?: string }).code === "P2002"
    ) {
      return NextResponse.json({ error: "Credencial com mesmo titulo e usuario ja existe" }, { status: 409 })
    }
    return NextResponse.json({ error: "Erro ao criar credencial" }, { status: 500 })
  }
}

NOVAPRATA_EOF
mkdir -p "src/components"
cat > "src/components/command-palette.tsx" << 'NOVAPRATA_EOF'
"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import {
  Search, LayoutDashboard, Box, Users, Lock, Network, PenTool,
  Ticket, FileText, Building2, BarChart3, Settings, Loader2, CornerDownLeft,
} from "lucide-react"

const NAV_COMMANDS = [
  { label: "Ir para Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { label: "Ir para Ativos", href: "/assets", icon: Box },
  { label: "Ir para Colaboradores", href: "/employees", icon: Users },
  { label: "Ir para Cofre", href: "/vault", icon: Lock },
  { label: "Ir para Rede", href: "/network", icon: Network },
  { label: "Ir para Manutenção", href: "/maintenances", icon: PenTool },
  { label: "Ir para Chamados", href: "/tickets", icon: Ticket },
  { label: "Ir para Certificados/Licenças", href: "/documents", icon: FileText },
  { label: "Ir para Fornecedores", href: "/suppliers", icon: Building2 },
  { label: "Ir para Relatórios", href: "/reports", icon: BarChart3 },
  { label: "Ir para Configurações", href: "/settings", icon: Settings },
]

interface SearchResult {
  type: string
  id: string
  label: string
  sublabel: string
  href: string
}

export function CommandPalette() {
  const [isOpen, setIsOpen] = React.useState(false)
  const [query, setQuery] = React.useState("")
  const [results, setResults] = React.useState<SearchResult[]>([])
  const [searching, setSearching] = React.useState(false)
  const inputRef = React.useRef<HTMLInputElement>(null)
  const router = useRouter()

  React.useEffect(() => {
    function handleKeydown(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault()
        setIsOpen((prev) => !prev)
      }
      if (e.key === "Escape") setIsOpen(false)
    }
    document.addEventListener("keydown", handleKeydown)
    return () => document.removeEventListener("keydown", handleKeydown)
  }, [])

  React.useEffect(() => {
    if (isOpen) {
      setTimeout(() => inputRef.current?.focus(), 50)
    } else {
      setQuery("")
      setResults([])
    }
  }, [isOpen])

  React.useEffect(() => {
    if (query.trim().length < 2) {
      setResults([])
      return
    }
    setSearching(true)
    const handle = setTimeout(async () => {
      try {
        const res = await fetch(`/api/search?q=${encodeURIComponent(query.trim())}`)
        const data = await res.json()
        setResults(data.results || [])
      } catch {
        setResults([])
      } finally {
        setSearching(false)
      }
    }, 250)
    return () => clearTimeout(handle)
  }, [query])

  const filteredNav = NAV_COMMANDS.filter((c) =>
    c.label.toLowerCase().includes(query.toLowerCase())
  )

  function go(href: string) {
    setIsOpen(false)
    router.push(href)
  }

  // Expõe globalmente pra topbar poder abrir a palette clicando na barra de busca
  React.useEffect(() => {
    ;(window as any).__openCommandPalette = () => setIsOpen(true)
  }, [])

  if (!isOpen) return null

  return (
    <div
      className="fixed inset-0 z-[120] flex items-start justify-center pt-[15vh] p-4 backdrop-blur-sm animate-in fade-in duration-150"
      style={{ background: "var(--modal-overlay)" }}
      onClick={() => setIsOpen(false)}
    >
      <div
        className="w-full max-w-xl rounded-xl shadow-2xl overflow-hidden animate-in zoom-in-95 slide-in-from-top-4 duration-200"
        style={{ background: "var(--modal-bg)", border: "1px solid var(--modal-border)" }}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center gap-3 px-4 py-3 border-b" style={{ borderColor: "var(--modal-border)" }}>
          {searching ? (
            <Loader2 className="h-4 w-4 animate-spin flex-shrink-0" style={{ color: "var(--text-tertiary)" }} />
          ) : (
            <Search className="h-4 w-4 flex-shrink-0" style={{ color: "var(--text-tertiary)" }} />
          )}
          <input
            ref={inputRef}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Buscar ativos, chamados, colaboradores... ou navegar"
            className="flex-1 bg-transparent outline-none text-sm"
            style={{ color: "var(--text-primary)" }}
          />
          <kbd className="hidden sm:inline text-[10px] px-1.5 py-0.5 rounded border" style={{ borderColor: "var(--border-primary)", color: "var(--text-tertiary)" }}>
            Esc
          </kbd>
        </div>

        <div className="max-h-[50vh] overflow-y-auto p-2">
          {query.trim().length >= 2 && results.length > 0 && (
            <div className="mb-2">
              <p className="px-2 py-1 text-[10px] uppercase font-bold tracking-wide" style={{ color: "var(--text-tertiary)" }}>
                Resultados
              </p>
              {results.map((r) => (
                <button
                  key={`${r.type}-${r.id}`}
                  onClick={() => go(r.href)}
                  className="w-full flex items-center justify-between gap-3 px-3 py-2.5 rounded-lg text-left transition-colors hover:bg-[var(--sidebar-item-hover)]"
                >
                  <div className="min-w-0">
                    <p className="text-sm font-medium truncate" style={{ color: "var(--text-primary)" }}>{r.label}</p>
                    <p className="text-xs truncate" style={{ color: "var(--text-tertiary)" }}>{r.sublabel}</p>
                  </div>
                  <span className="text-[10px] px-2 py-0.5 rounded-full flex-shrink-0" style={{ background: "var(--sidebar-item-active-bg)", color: "var(--text-tertiary)" }}>
                    {r.type}
                  </span>
                </button>
              ))}
            </div>
          )}

          {query.trim().length >= 2 && !searching && results.length === 0 && (
            <p className="px-3 py-6 text-sm text-center" style={{ color: "var(--text-tertiary)" }}>
              Nada encontrado pra "{query}"
            </p>
          )}

          <div>
            {filteredNav.length > 0 && (
              <p className="px-2 py-1 text-[10px] uppercase font-bold tracking-wide" style={{ color: "var(--text-tertiary)" }}>
                Navegação
              </p>
            )}
            {filteredNav.map((c) => (
              <button
                key={c.href}
                onClick={() => go(c.href)}
                className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-left transition-colors hover:bg-[var(--sidebar-item-hover)]"
              >
                <c.icon className="h-4 w-4 flex-shrink-0" style={{ color: "var(--text-tertiary)" }} />
                <span className="text-sm" style={{ color: "var(--text-primary)" }}>{c.label}</span>
              </button>
            ))}
          </div>
        </div>

        <div className="flex items-center gap-4 px-4 py-2 border-t text-[10px]" style={{ borderColor: "var(--modal-border)", color: "var(--text-tertiary)" }}>
          <span className="flex items-center gap-1"><CornerDownLeft className="h-3 w-3" /> selecionar</span>
          <span>Cmd/Ctrl + K pra abrir/fechar</span>
        </div>
      </div>
    </div>
  )
}

NOVAPRATA_EOF
mkdir -p "src/components"
cat > "src/components/confirm-dialog-provider.tsx" << 'NOVAPRATA_EOF'
"use client"

import * as React from "react"
import { AlertTriangle } from "lucide-react"
import { Button } from "@/components/ui/button"

interface ConfirmOptions {
  title?: string
  message: string
  confirmLabel?: string
  cancelLabel?: string
  destructive?: boolean
}

interface PendingConfirm extends ConfirmOptions {
  resolve: (value: boolean) => void
}

interface ConfirmContextValue {
  confirm: (options: ConfirmOptions | string) => Promise<boolean>
}

const ConfirmContext = React.createContext<ConfirmContextValue | null>(null)

export function ConfirmDialogProvider({ children }: { children: React.ReactNode }) {
  const [pending, setPending] = React.useState<PendingConfirm | null>(null)

  const confirm = React.useCallback((options: ConfirmOptions | string) => {
    const normalized: ConfirmOptions = typeof options === "string" ? { message: options } : options
    return new Promise<boolean>((resolve) => {
      setPending({ ...normalized, resolve })
    })
  }, [])

  function handle(result: boolean) {
    pending?.resolve(result)
    setPending(null)
  }

  React.useEffect(() => {
    function handleEscape(e: KeyboardEvent) {
      if (e.key === "Escape" && pending) handle(false)
    }
    document.addEventListener("keydown", handleEscape)
    return () => document.removeEventListener("keydown", handleEscape)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pending])

  return (
    <ConfirmContext.Provider value={{ confirm }}>
      {children}
      {pending && (
        <div className="fixed inset-0 z-[110] flex items-center justify-center p-4 backdrop-blur-sm animate-in fade-in duration-200" style={{ background: "var(--modal-overlay)" }}>
          <div
            className="w-full max-w-sm rounded-xl shadow-2xl overflow-hidden animate-in zoom-in-95 duration-200"
            style={{ background: "var(--modal-bg)", border: "1px solid var(--modal-border)" }}
          >
            <div className="p-6 flex gap-4">
              <div
                className="h-10 w-10 rounded-full flex items-center justify-center flex-shrink-0"
                style={{
                  background: pending.destructive ? "var(--status-error-bg)" : "var(--status-warning-bg)",
                  color: pending.destructive ? "var(--status-error)" : "var(--status-warning)",
                }}
              >
                <AlertTriangle className="h-5 w-5" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold text-base" style={{ color: "var(--text-primary)" }}>
                  {pending.title || "Confirmar ação"}
                </h3>
                <p className="text-sm mt-1.5" style={{ color: "var(--text-tertiary)" }}>
                  {pending.message}
                </p>
              </div>
            </div>
            <div className="flex justify-end gap-2 px-6 py-4 border-t" style={{ borderColor: "var(--modal-border)" }}>
              <Button variant="outline" size="sm" onClick={() => handle(false)}>
                {pending.cancelLabel || "Cancelar"}
              </Button>
              <Button
                variant={pending.destructive ? "destructive" : "default"}
                size="sm"
                onClick={() => handle(true)}
              >
                {pending.confirmLabel || "Confirmar"}
              </Button>
            </div>
          </div>
        </div>
      )}
    </ConfirmContext.Provider>
  )
}

export function useConfirm() {
  const ctx = React.useContext(ConfirmContext)
  if (!ctx) throw new Error("useConfirm precisa estar dentro de <ConfirmDialogProvider>")
  return ctx.confirm
}

NOVAPRATA_EOF
mkdir -p "src/components/features/employees"
cat > "src/components/features/employees/EmployeeForm.tsx" << 'NOVAPRATA_EOF'
"use client"

import * as React from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Loader2 } from "lucide-react"

interface EmployeeFormProps {
  initialData?: any
  onSubmit: (data: any) => Promise<void>
  onCancel: () => void
}

export function EmployeeForm({ initialData, onSubmit, onCancel }: EmployeeFormProps) {
  const [loading, setLoading] = React.useState(false)
  const [formData, setFormData] = React.useState({
    name: initialData?.name || "",
    email: initialData?.email || "",
    phone: initialData?.phone || "",
    department: initialData?.department || "",
    jobTitle: initialData?.jobTitle || "",
    role: initialData?.role || "USER",
    status: initialData?.status || "ATIVO",
    newPassword: "",
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
          <label className="text-sm font-medium">E-mail</label>
          <Input
            type="email"
            required
            disabled={!!initialData}
            value={formData.email}
            onChange={e => setFormData({ ...formData, email: e.target.value })}
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Telefone</label>
          <Input
            placeholder="(66) 99999-9999"
            value={formData.phone}
            onChange={e => setFormData({ ...formData, phone: e.target.value })}
          />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Cargo</label>
          <Input value={formData.jobTitle} onChange={e => setFormData({ ...formData, jobTitle: e.target.value })} />
        </div>
      </div>

      <div className="grid grid-cols-3 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Setor</label>
          <Input
            placeholder="Escritório, Barracão..."
            value={formData.department}
            onChange={e => setFormData({ ...formData, department: e.target.value })}
          />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Nível de Acesso</label>
          <select
            className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            value={formData.role}
            onChange={e => setFormData({ ...formData, role: e.target.value })}
          >
            <option value="USER">Usuário</option>
            <option value="TECHNICIAN">Técnico</option>
            <option value="ADMIN">Admin</option>
          </select>
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Status</label>
          <select
            className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            value={formData.status}
            onChange={e => setFormData({ ...formData, status: e.target.value })}
          >
            <option value="ATIVO">Ativo</option>
            <option value="INATIVO">Inativo</option>
          </select>
        </div>
      </div>

      {initialData ? (
        <div className="space-y-2 pt-2 border-t">
          <label className="text-sm font-medium">Definir nova senha de acesso</label>
          <Input
            type="password"
            placeholder="Deixe em branco para não alterar"
            value={formData.newPassword}
            onChange={e => setFormData({ ...formData, newPassword: e.target.value })}
          />
          <p className="text-xs text-muted-foreground">
            Use isso pra dar acesso a um colaborador que ainda não consegue entrar no sistema. Avise a senha por um canal seguro (não por aqui).
          </p>
        </div>
      ) : (
        <p className="text-xs text-muted-foreground">
          O colaborador é criado com uma senha temporária aleatória. Depois de criar, edite o cadastro dele pra definir uma senha de acesso e avisá-lo.
        </p>
      )}

      <div className="flex justify-end gap-3 pt-4 border-t">
        <Button variant="outline" type="button" onClick={onCancel}>Cancelar</Button>
        <Button type="submit" disabled={loading}>
          {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : initialData ? "Salvar" : "Criar Colaborador"}
        </Button>
      </div>
    </form>
  )
}

NOVAPRATA_EOF
mkdir -p "src/components"
cat > "src/components/notification-bell.tsx" << 'NOVAPRATA_EOF'
"use client"

import * as React from "react"
import Link from "next/link"
import { Bell, AlertTriangle, FileWarning, CheckCircle2 } from "lucide-react"
import { Button } from "@/components/ui/button"

interface Notification {
  id: string
  type: "sla" | "document"
  title: string
  description: string
  href: string
  severity: "critical" | "warning"
}

export function NotificationBell() {
  const [isOpen, setIsOpen] = React.useState(false)
  const [notifications, setNotifications] = React.useState<Notification[]>([])
  const [loading, setLoading] = React.useState(true)
  const ref = React.useRef<HTMLDivElement>(null)

  React.useEffect(() => {
    async function fetchNotifications() {
      try {
        const res = await fetch("/api/notifications")
        const data = await res.json()
        setNotifications(data.notifications || [])
      } catch {
        // silencioso: sino sem dado não deve quebrar o topbar
      } finally {
        setLoading(false)
      }
    }
    fetchNotifications()
    const interval = setInterval(fetchNotifications, 60000)
    return () => clearInterval(interval)
  }, [])

  React.useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setIsOpen(false)
    }
    document.addEventListener("mousedown", handleClickOutside)
    return () => document.removeEventListener("mousedown", handleClickOutside)
  }, [])

  const criticalCount = notifications.filter((n) => n.severity === "critical").length

  return (
    <div className="relative" ref={ref}>
      <Button
        variant="ghost"
        size="icon"
        className="relative h-9 w-9 text-zinc-400 hover:text-zinc-200"
        onClick={() => setIsOpen((v) => !v)}
      >
        <Bell className="h-4 w-4" />
        {notifications.length > 0 && (
          <span className="absolute right-1.5 top-1.5 flex h-4 min-w-[16px] items-center justify-center rounded-full px-1 text-[9px] font-bold text-white" style={{ background: criticalCount > 0 ? "#ef4444" : "#f59e0b" }}>
            {notifications.length > 9 ? "9+" : notifications.length}
          </span>
        )}
      </Button>

      {isOpen && (
        <div
          className="absolute right-0 top-full mt-2 w-80 rounded-xl shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-150 z-50"
          style={{ background: "var(--modal-bg)", border: "1px solid var(--modal-border)" }}
        >
          <div className="px-4 py-3 border-b flex items-center justify-between" style={{ borderColor: "var(--modal-border)" }}>
            <p className="text-sm font-semibold" style={{ color: "var(--text-primary)" }}>Notificações</p>
            {notifications.length > 0 && (
              <span className="text-[10px]" style={{ color: "var(--text-tertiary)" }}>{notifications.length} pendente(s)</span>
            )}
          </div>
          <div className="max-h-80 overflow-y-auto">
            {loading ? (
              <p className="px-4 py-6 text-sm text-center" style={{ color: "var(--text-tertiary)" }}>Carregando...</p>
            ) : notifications.length === 0 ? (
              <div className="px-4 py-8 text-center">
                <CheckCircle2 className="h-8 w-8 mx-auto mb-2 text-emerald-500" />
                <p className="text-sm" style={{ color: "var(--text-tertiary)" }}>Tudo em dia. Nenhum alerta agora.</p>
              </div>
            ) : (
              notifications.map((n) => (
                <Link
                  key={n.id}
                  href={n.href}
                  onClick={() => setIsOpen(false)}
                  className="flex items-start gap-3 px-4 py-3 transition-colors hover:bg-[var(--sidebar-item-hover)] border-b last:border-0"
                  style={{ borderColor: "var(--modal-border)" }}
                >
                  {n.type === "sla" ? (
                    <AlertTriangle className={`h-4 w-4 mt-0.5 flex-shrink-0 ${n.severity === "critical" ? "text-red-500" : "text-amber-500"}`} />
                  ) : (
                    <FileWarning className={`h-4 w-4 mt-0.5 flex-shrink-0 ${n.severity === "critical" ? "text-red-500" : "text-amber-500"}`} />
                  )}
                  <div className="min-w-0">
                    <p className="text-sm font-medium" style={{ color: "var(--text-primary)" }}>{n.title}</p>
                    <p className="text-xs truncate" style={{ color: "var(--text-tertiary)" }}>{n.description}</p>
                  </div>
                </Link>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  )
}

NOVAPRATA_EOF
mkdir -p "src/components"
cat > "src/components/toast-provider.tsx" << 'NOVAPRATA_EOF'
"use client"

import * as React from "react"
import { Toast, type ToastType } from "@/components/ui/toast"

interface ToastItem {
  id: number
  type: ToastType
  title: string
  description?: string
}

interface ToastContextValue {
  notify: (title: string, options?: { type?: ToastType; description?: string }) => void
  success: (title: string, description?: string) => void
  error: (title: string, description?: string) => void
}

const ToastContext = React.createContext<ToastContextValue | null>(null)

export function ToastQueueProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = React.useState<ToastItem[]>([])
  const idRef = React.useRef(0)

  const notify = React.useCallback((title: string, options?: { type?: ToastType; description?: string }) => {
    const id = ++idRef.current
    setItems((prev) => [...prev, { id, title, type: options?.type || "info", description: options?.description }])
  }, [])

  const success = React.useCallback((title: string, description?: string) => notify(title, { type: "success", description }), [notify])
  const error = React.useCallback((title: string, description?: string) => notify(title, { type: "error", description }), [notify])

  function dismiss(id: number) {
    setItems((prev) => prev.filter((t) => t.id !== id))
  }

  return (
    <ToastContext.Provider value={{ notify, success, error }}>
      {children}
      <div className="fixed bottom-4 right-4 z-[100] flex flex-col gap-2 w-full max-w-sm">
        {items.map((item) => (
          <Toast
            key={item.id}
            type={item.type}
            title={item.title}
            description={item.description}
            onClose={() => dismiss(item.id)}
          />
        ))}
      </div>
    </ToastContext.Provider>
  )
}

export function useToast() {
  const ctx = React.useContext(ToastContext)
  if (!ctx) throw new Error("useToast precisa estar dentro de <ToastQueueProvider>")
  return ctx
}

NOVAPRATA_EOF
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
echo "Arquivos escritos."
echo "Agora rode: npm install && npx prisma generate && npm run build"
