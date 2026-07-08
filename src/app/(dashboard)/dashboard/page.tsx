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
import { AuroraGlow } from "@/components/aurora-glow"
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
    <div className="relative space-y-10 animate-in fade-in duration-500">
      <AuroraGlow />
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
                      <stop offset="5%" stopColor="#6366f1" stopOpacity={0.4} />
                      <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
                  <XAxis dataKey="date" fontSize={11} tickLine={false} />
                  <YAxis fontSize={11} tickLine={false} allowDecimals={false} width={28} />
                  <Tooltip />
                  <Area type="monotone" dataKey="abertos" stroke="#6366f1" fill="url(#colorAbertos)" strokeWidth={2} />
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
                  <Bar dataKey="count" fill="#6366f1" radius={[0, 4, 4, 0]} />
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
                      style={{ background: "rgba(99, 102, 241, 0.15)", color: "#6366f1" }}
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
                      style={{ color: "#6366f1", background: "rgba(99, 102, 241, 0.1)" }}
                    >
                      {item._count._all}
                    </span>
                  </div>
                  <div className="h-2 w-full rounded-full overflow-hidden" style={{ background: "var(--border-primary)" }}>
                    <div
                      className="h-full transition-all duration-700 rounded-full"
                      style={{
                        width: `${(item._count._all / Math.max(stats.totalAssets || 1, 1)) * 100}%`,
                        background: "linear-gradient(90deg, #6366f1, #818cf8)",
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

