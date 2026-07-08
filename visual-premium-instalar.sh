#!/usr/bin/env bash
set -e
echo "Escrevendo nova paleta e efeitos visuais..."
mkdir -p "src/app"
cat > "src/app/globals.css" << 'NOVAPRATA_EOF'
@import "tailwindcss";

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-card: var(--card);
  --color-card-foreground: var(--card-foreground);
  --color-popover: var(--popover);
  --color-popover-foreground: var(--popover-foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-secondary: var(--secondary);
  --color-secondary-foreground: var(--secondary-foreground);
  --color-muted: var(--muted);
  --color-muted-foreground: var(--muted-foreground);
  --color-accent: var(--accent);
  --color-accent-foreground: var(--accent-foreground);
  --color-destructive: var(--destructive);
  --color-destructive-foreground: var(--destructive-foreground);
  --color-border: var(--border);
  --color-input: var(--input);
  --color-ring: var(--ring);
  --color-signal: var(--signal);
  --radius-lg: var(--radius);
  --radius-md: calc(var(--radius) - 2px);
  --radius-sm: calc(var(--radius) - 4px);
}

:root {
  --background: #ffffff;
  --foreground: #020617;
  --card: #ffffff;
  --card-foreground: #020617;
  --popover: #ffffff;
  --popover-foreground: #020617;
  --primary: #4f46e5;
  --primary-foreground: #f8fafc;
  --secondary: #f1f5f9;
  --secondary-foreground: #0f172a;
  --muted: #f1f5f9;
  --muted-foreground: #64748b;
  --accent: #f1f5f9;
  --accent-foreground: #0f172a;
  --destructive: #ef4444;
  --destructive-foreground: #f8fafc;
  --border: #e2e8f0;
  --input: #e2e8f0;
  --ring: #4f46e5;
  --radius: 0.75rem;
  --signal: #0891b2;
  --signal-bg: rgba(8, 145, 178, 0.12);
}

.dark {
  --background: #0f111a;
  --foreground: #f8fafc;
  --card: #1a1d27;
  --card-foreground: #f8fafc;
  --popover: #1a1d27;
  --popover-foreground: #f8fafc;
  --primary: #6366f1;
  --primary-foreground: #f8fafc;
  --secondary: #1e293b;
  --secondary-foreground: #f8fafc;
  --muted: #1e293b;
  --muted-foreground: #94a3b8;
  --accent: #1e293b;
  --accent-foreground: #f8fafc;
  --destructive: #ef4444;
  --destructive-foreground: #f8fafc;
  --border: #1e293b;
  --input: #1e293b;
  --ring: #6366f1;
  --signal: #22d3ee;
  --signal-bg: rgba(34, 211, 238, 0.12);
}

body {
  background: var(--background);
  color: var(--foreground);
  font-feature-settings: "rlig" 1, "calt" 1;
}

@keyframes aurora-pulse {
  0%, 100% { transform: scale(1) translateY(0); opacity: 0.16; }
  50% { transform: scale(1.15) translateY(20px); opacity: 0.24; }
}

@layer base {
  * {
    @apply border-border;
  }
}

NOVAPRATA_EOF
mkdir -p "src/styles"
cat > "src/styles/theme-colors.css" << 'NOVAPRATA_EOF'
/* Theme Color Tokens */

/* Dark Mode (Default) */
[data-theme="dark"],
:root {
  /* Backgrounds */
  --bg-primary: #0F111A;
  --bg-secondary: #151823;
  --bg-tertiary: #1a1f2e;
  --bg-hover: rgba(99, 102, 241, 0.06);
  --bg-muted: rgba(255, 255, 255, 0.02);

  /* Text */
  --text-primary: #ffffff;
  --text-secondary: #e5e7eb;
  --text-tertiary: #a1a5b0;
  --text-muted: #6b7280;

  /* Borders */
  --border-primary: rgba(255, 255, 255, 0.06);
  --border-secondary: rgba(255, 255, 255, 0.08);
  --border-hover: rgba(99, 102, 241, 0.35);

  /* Cards & Components */
  --card-bg: #151823;
  --card-border: rgba(255, 255, 255, 0.06);

  /* Inputs */
  --input-bg: #1a1f2e;
  --input-bg-focus: #202734;
  --input-border: rgba(255, 255, 255, 0.08);
  --input-border-focus: rgba(99, 102, 241, 0.4);
  --input-text: #e5e7eb;
  --input-placeholder: #6b7280;

  /* Buttons */
  --btn-primary-bg: #6366f1;
  --btn-primary-bg-hover: #4f46e5;
  --btn-primary-text: #ffffff;
  --btn-secondary-bg: rgba(229, 231, 235, 0.1);
  --btn-secondary-hover: rgba(229, 231, 235, 0.15);
  --btn-ghost-hover: rgba(255, 255, 255, 0.08);

  /* Status Colors */
  --status-success: #10b981;
  --status-success-bg: rgba(16, 185, 129, 0.15);
  --status-warning: #f59e0b;
  --status-warning-bg: rgba(245, 158, 11, 0.15);
  --status-error: #ef4444;
  --status-error-bg: rgba(239, 68, 68, 0.15);
  --status-info: #3b82f6;
  --status-info-bg: rgba(59, 130, 246, 0.15);

  /* Sidebar */
  --sidebar-bg: #0F111A;
  --sidebar-border: rgba(255, 255, 255, 0.05);
  --sidebar-item-hover: rgba(255, 255, 255, 0.04);
  --sidebar-item-active-bg: rgba(99, 102, 241, 0.12);
  --sidebar-item-active-border: rgba(99, 102, 241, 0.35);
  --sidebar-item-active-text: #ffffff;

  /* Topbar */
  --topbar-bg: #0F111A;
  --topbar-border: rgba(255, 255, 255, 0.05);

  /* Modal */
  --modal-bg: #151823;
  --modal-border: rgba(255, 255, 255, 0.06);
  --modal-overlay: rgba(0, 0, 0, 0.5);
}

/* Light Mode */
[data-theme="light"] {
  /* Backgrounds */
  --bg-primary: #f3f4f6;
  --bg-secondary: #ffffff;
  --bg-tertiary: #eef2f7;
  --bg-hover: #f0f4f9;
  --bg-muted: #fafbfc;

  /* Text */
  --text-primary: #0a0e27;
  --text-secondary: #1e293b;
  --text-tertiary: #64748b;
  --text-muted: #94a3b8;

  /* Borders */
  --border-primary: #dce4f0;
  --border-secondary: #cad5e3;
  --border-hover: #4f46e5;

  /* Cards & Components */
  --card-bg: #ffffff;
  --card-border: #dce4f0;
  --card-shadow: 0 1px 3px rgba(0, 0, 0, 0.08), 0 1px 2px rgba(0, 0, 0, 0.04);

  /* Inputs */
  --input-bg: #f8fafc;
  --input-bg-focus: #f1f5f9;
  --input-border: #cbd5e1;
  --input-border-focus: #4f46e5;
  --input-text: #0a0e27;
  --input-placeholder: #94a3b8;

  /* Buttons */
  --btn-primary-bg: #6366f1;
  --btn-primary-bg-hover: #4f46e5;
  --btn-primary-text: #ffffff;
  --btn-secondary-bg: #e0e7ff;
  --btn-secondary-hover: #c7d2fe;
  --btn-ghost-hover: #f1f5f9;

  /* Status Colors */
  --status-success: #10b981;
  --status-success-bg: #d1fae5;
  --status-warning: #f59e0b;
  --status-warning-bg: #fef3c7;
  --status-error: #ef4444;
  --status-error-bg: #fee2e2;
  --status-info: #3b82f6;
  --status-info-bg: #dbeafe;

  /* Sidebar */
  --sidebar-bg: #ffffff;
  --sidebar-border: #dce4f0;
  --sidebar-item-hover: #f8fafc;
  --sidebar-item-active-bg: #eef2ff;
  --sidebar-item-active-border: #4f46e5;
  --sidebar-item-active-text: #4338ca;
  --sidebar-item-active-shadow: 0 0 0 3px rgba(79, 70, 229, 0.12);

  /* Topbar */
  --topbar-bg: #ffffff;
  --topbar-border: #dce4f0;

  /* Modal */
  --modal-bg: #ffffff;
  --modal-border: #dce4f0;
  --modal-overlay: rgba(0, 0, 0, 0.3);
}

/* Smooth theme transitions */
* {
  transition: background-color 0.3s ease, color 0.3s ease, border-color 0.3s ease;
}

/* Avoid transition on initial load */
.no-transition * {
  transition: none !important;
}

NOVAPRATA_EOF
mkdir -p "src/components"
cat > "src/components/aurora-glow.tsx" << 'NOVAPRATA_EOF'
"use client"

// Elemento de assinatura visual do NovaPrata Labs: um brilho ambiente sutil,
// nas cores da marca (indigo) + sinal ao vivo (ciano), evocando um pulso de
// monitoramento — combina com o produto (SLA, rede, uptime).
// Respeita prefers-reduced-motion.
export function AuroraGlow() {
  return (
    <div
      aria-hidden
      className="pointer-events-none absolute inset-x-0 top-0 -z-10 h-[420px] overflow-hidden"
    >
      <div
        className="absolute -top-40 left-[8%] h-[420px] w-[420px] rounded-full opacity-[0.16] blur-[110px] motion-safe:animate-[aurora-pulse_9s_ease-in-out_infinite]"
        style={{ background: "radial-gradient(circle, var(--primary) 0%, transparent 70%)" }}
      />
      <div
        className="absolute -top-32 right-[10%] h-[360px] w-[360px] rounded-full opacity-[0.12] blur-[110px] motion-safe:animate-[aurora-pulse_11s_ease-in-out_infinite_1.5s]"
        style={{ background: "radial-gradient(circle, var(--signal) 0%, transparent 70%)" }}
      />
    </div>
  )
}

NOVAPRATA_EOF
mkdir -p "src/components/ui"
cat > "src/components/ui/button.tsx" << 'NOVAPRATA_EOF'
import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const buttonVariants = cva(
  "inline-flex items-center justify-center whitespace-nowrap rounded-lg text-sm font-medium transition-all duration-200 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/50 disabled:pointer-events-none disabled:opacity-50 active:scale-95",
  {
    variants: {
      variant: {
        default:
          "bg-primary text-primary-foreground hover:brightness-110 active:brightness-95 shadow-sm shadow-primary/20",
        destructive:
          "bg-red-500/15 text-red-300 border border-red-500/25 hover:bg-red-500/25",
        outline:
          "border border-zinc-700/50 bg-background hover:bg-zinc-900/50 hover:border-zinc-600/50",
        secondary:
          "bg-zinc-700/30 text-zinc-200 border border-zinc-600/50 hover:bg-zinc-700/50",
        ghost: "hover:bg-zinc-900/40 hover:text-zinc-100 text-zinc-400",
        link: "text-primary hover:brightness-125 underline-offset-4 hover:underline",
      },
      size: {
        default: "h-9 px-4 py-2",
        sm: "h-8 rounded-lg px-3 text-xs",
        lg: "h-10 rounded-lg px-8",
        icon: "h-9 w-9",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button"
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = "Button"

export { Button, buttonVariants }

NOVAPRATA_EOF
mkdir -p "src/components/ui"
cat > "src/components/ui/badge.tsx" << 'NOVAPRATA_EOF'
import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const badgeVariants = cva(
  "inline-flex items-center rounded-md px-2.5 py-1 text-xs font-semibold transition-colors duration-200",
  {
    variants: {
      variant: {
        default:
          "dark:bg-primary/15 dark:text-[#a5b4fc] dark:border-primary/25 bg-indigo-50 text-indigo-700 border border-indigo-200",
        secondary:
          "dark:bg-zinc-500/10 dark:text-zinc-300 dark:border-zinc-500/20 bg-gray-50 text-gray-700 border border-gray-200",
        destructive:
          "dark:bg-red-500/15 dark:text-red-300 dark:border-red-500/25 bg-red-50 text-red-700 border border-red-200",
        outline: "dark:border-zinc-500/20 dark:bg-transparent dark:text-zinc-300 border border-gray-300 bg-transparent text-gray-700",
        success: "dark:bg-emerald-500/15 dark:text-emerald-300 dark:border-emerald-500/25 bg-emerald-50 text-emerald-700 border border-emerald-200",
        warning: "dark:bg-amber-500/15 dark:text-amber-300 dark:border-amber-500/25 bg-amber-50 text-amber-700 border border-amber-200",
        ghost: "dark:bg-zinc-900/40 dark:text-zinc-300 dark:border-zinc-700/20 bg-gray-50 text-gray-700 border border-gray-200",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
)

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return (
    <div className={cn(badgeVariants({ variant }), className)} {...props} />
  )
}

export { Badge, badgeVariants }

NOVAPRATA_EOF
mkdir -p "src/components/ui"
cat > "src/components/ui/input.tsx" << 'NOVAPRATA_EOF'
import * as React from "react"
import { cn } from "@/lib/utils"

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          "flex h-9 w-full rounded-lg border px-3 py-2 text-sm transition-all duration-200 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-[var(--input-placeholder)] focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/50 disabled:cursor-not-allowed disabled:opacity-50",
          className
        )}
        style={{
          background: "var(--input-bg)",
          borderColor: "var(--input-border)",
          color: "var(--input-text)"
        }}
        onFocus={(e) => {
          e.currentTarget.style.background = "var(--input-bg-focus)"
          e.currentTarget.style.borderColor = "var(--input-border-focus)"
        }}
        onBlur={(e) => {
          e.currentTarget.style.background = "var(--input-bg)"
          e.currentTarget.style.borderColor = "var(--input-border)"
        }}
        ref={ref}
        {...props}
      />
    )
  }
)
Input.displayName = "Input"

export { Input }

NOVAPRATA_EOF
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
            <div className="relative min-w-[32px] bg-primary/90 p-1.5 rounded-lg hover:bg-primary transition-colors">
              <Monitor className="w-5 h-5 text-white" />
              <span className="absolute -right-0.5 -top-0.5 flex h-2.5 w-2.5">
                <span className="absolute inline-flex h-full w-full animate-ping rounded-full opacity-75" style={{ background: "var(--signal)" }} />
                <span className="relative inline-flex h-2.5 w-2.5 rounded-full border border-black/20" style={{ background: "var(--signal)" }} />
              </span>
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
echo "Arquivos escritos."
echo "Agora rode: npm install && npx prisma generate && npm run build"
