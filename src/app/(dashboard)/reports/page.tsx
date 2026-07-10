"use client"

import React from "react"
import {
  BarChart3,
  FileText,
  Download,
  ArrowUpRight,
  PieChart,
  Activity,
  Calendar,
  Filter,
  Loader2,
  Mail,
  MessageCircle,
  Sparkles,
} from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { Input } from "@/components/ui/input"

type ReportsStats = {
  monthlyCost: number
  availability: number
  newAssetsThisMonth: number
  pendingActions: number
  totalAssets: number
  assetsInMaintenance: number
  periodStart: string
}

type ReportTemplateKey =
  | "ASSET_INVENTORY"
  | "ASSET_DEPRECIATION"
  | "LICENSE_COMPLIANCE"
  | "MAINTENANCE_HISTORY"
  | "VAULT_AUDIT"

type ReportFormat = "PDF" | "XLSX" | "CSV" | "JSON"
type ReportPeriod = "THIS_MONTH" | "LAST_7_DAYS" | "LAST_30_DAYS" | "LAST_90_DAYS" | "CUSTOM"
type DeliveryChannel = "DOWNLOAD" | "EMAIL" | "WHATSAPP"

type ReportTemplateMeta = {
  key: ReportTemplateKey
  title: string
  desc: string
  type: string
}

const reportTemplates: ReportTemplateMeta[] = [
  {
    key: "ASSET_INVENTORY",
    title: "Inventário Geral de Ativos",
    desc: "Listagem completa de ativos, status e responsável.",
    type: "PDF / XLSX / CSV / JSON",
  },
  {
    key: "ASSET_DEPRECIATION",
    title: "Depreciação de Equipamentos",
    desc: "Estimativa de valor contábil por tempo de uso.",
    type: "PDF / XLSX / CSV / JSON",
  },
  {
    key: "LICENSE_COMPLIANCE",
    title: "Relatório de Licenciamento",
    desc: "Conformidade de inventário de software e SO.",
    type: "PDF / XLSX / CSV / JSON",
  },
  {
    key: "MAINTENANCE_HISTORY",
    title: "Histórico de Manutenções",
    desc: "Custos, técnicos e progresso no período.",
    type: "PDF / XLSX / CSV / JSON",
  },
  {
    key: "VAULT_AUDIT",
    title: "Log de Acesso ao Cofre",
    desc: "Auditoria de visualização e cópia de credenciais.",
    type: "PDF / XLSX / CSV / JSON",
  },
]

function formatCurrencyBRL(value: number) {
  return new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
    maximumFractionDigits: 0,
  }).format(value)
}

function inferFilename(disposition: string | null, fallback: string) {
  if (!disposition) return fallback
  const match = disposition.match(/filename="(.+?)"/i)
  return match?.[1] || fallback
}

export default function ReportsPage() {
  const [stats, setStats] = React.useState<ReportsStats | null>(null)
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState<string | null>(null)

  const [selectedTemplate, setSelectedTemplate] = React.useState<ReportTemplateKey>("ASSET_INVENTORY")
  const [selectedFormat, setSelectedFormat] = React.useState<ReportFormat>("PDF")
  const [selectedPeriod, setSelectedPeriod] = React.useState<ReportPeriod>("THIS_MONTH")
  const [deliveryChannel, setDeliveryChannel] = React.useState<DeliveryChannel>("DOWNLOAD")
  const [recipient, setRecipient] = React.useState("")
  const [customFrom, setCustomFrom] = React.useState("")
  const [customTo, setCustomTo] = React.useState("")
  const [isExportModalOpen, setIsExportModalOpen] = React.useState(false)
  const [exporting, setExporting] = React.useState(false)
  const [actionMessage, setActionMessage] = React.useState<string | null>(null)
  const [actionError, setActionError] = React.useState<string | null>(null)
  const [lastDeliveryUrl, setLastDeliveryUrl] = React.useState<string | null>(null)

  React.useEffect(() => {
    async function loadStats() {
      try {
        setError(null)
        const res = await fetch("/api/reports/stats")
        if (!res.ok) {
          const data = (await res.json().catch(() => ({}))) as { error?: string }
          throw new Error(data.error || "Falha ao carregar indicadores")
        }

        const data = (await res.json()) as ReportsStats
        setStats(data)
      } catch (err) {
        setError(err instanceof Error ? err.message : "Erro inesperado")
      } finally {
        setLoading(false)
      }
    }

    loadStats()
  }, [])

  const periodLabel = stats
    ? new Date(stats.periodStart).toLocaleDateString("pt-BR", {
        month: "long",
        year: "numeric",
      })
    : new Date().toLocaleDateString("pt-BR", { month: "long", year: "numeric" })

  const selectedTemplateMeta = reportTemplates.find((template) => template.key === selectedTemplate) || reportTemplates[0]

  async function handleExportSubmit(e: React.FormEvent) {
    e.preventDefault()
    setExporting(true)
    setActionMessage(null)
    setActionError(null)
    setLastDeliveryUrl(null)

    try {
      if (deliveryChannel !== "DOWNLOAD" && !recipient.trim()) {
        throw new Error("Informe o destinatário para envio.")
      }

      if (selectedPeriod === "CUSTOM" && (!customFrom || !customTo)) {
        throw new Error("Informe a data inicial e final para período customizado.")
      }

      const payload = {
        template: selectedTemplate,
        format: selectedFormat,
        period: selectedPeriod,
        delivery: deliveryChannel,
        recipient: deliveryChannel === "DOWNLOAD" ? undefined : recipient.trim(),
        fromDate: selectedPeriod === "CUSTOM" ? customFrom : undefined,
        toDate: selectedPeriod === "CUSTOM" ? customTo : undefined,
      }

      const response = await fetch("/api/reports/export", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      })

      if (!response.ok) {
        const text = await response.text()
        try {
          const asJson = JSON.parse(text) as { error?: string }
          throw new Error(asJson.error || "Falha na exportação")
        } catch {
          throw new Error(text || "Falha na exportação")
        }
      }

      if (deliveryChannel === "DOWNLOAD") {
        const blob = await response.blob()
        const filename = inferFilename(
          response.headers.get("content-disposition"),
          `relatorio.${selectedFormat.toLowerCase()}`
        )
        const url = window.URL.createObjectURL(blob)
        const a = document.createElement("a")
        a.href = url
        a.download = filename
        document.body.appendChild(a)
        a.click()
        a.remove()
        window.URL.revokeObjectURL(url)

        setActionMessage(`Relatório gerado com sucesso (${filename}).`)
      } else {
        const data = (await response.json()) as { message?: string; downloadUrl?: string }
        setActionMessage(data.message || "Relatório enviado com sucesso.")
        setLastDeliveryUrl(data.downloadUrl || null)
      }
    } catch (err) {
      setActionError(err instanceof Error ? err.message : "Erro inesperado")
    } finally {
      setExporting(false)
      setIsExportModalOpen(false)
    }
  }

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Relatórios e BI</h1>
          <p className="text-muted-foreground">
            Análise dados reais da infraestrutura e gere documentos premium.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline">
            <Calendar className="mr-2 h-4 w-4" />
            {periodLabel}
          </Button>
          <Button className="bg-primary" onClick={() => setIsExportModalOpen(true)}>
            <Sparkles className="mr-2 h-4 w-4" />
            Gerar Relatório Premium
          </Button>
        </div>
      </div>

      {error && (
        <Card className="border-destructive/30 bg-destructive/5">
          <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
        </Card>
      )}

      {actionMessage && (
        <Card className="border-emerald-500/40 bg-emerald-500/5">
          <CardContent className="pt-6 text-sm text-emerald-700">
            {actionMessage}
            {lastDeliveryUrl && (
              <div className="mt-2 break-all">
                Link:{" "}
                <a href={lastDeliveryUrl} target="_blank" rel="noreferrer" className="underline">
                  {lastDeliveryUrl}
                </a>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {actionError && (
        <Card className="border-destructive/30 bg-destructive/5">
          <CardContent className="pt-6 text-sm text-destructive">{actionError}</CardContent>
        </Card>
      )}

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <Card className="hover:bg-muted/50 transition-all cursor-pointer border-dashed">
          <CardContent className="pt-6 flex flex-col items-center justify-center text-center space-y-2">
            <div className="p-3 bg-primary/10 rounded-full text-primary">
              <BarChart3 className="h-6 w-6" />
            </div>
            <p className="font-semibold text-sm">Custo Mensal</p>
            <p className="text-xl font-bold">
              {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : formatCurrencyBRL(stats?.monthlyCost ?? 0)}
            </p>
          </CardContent>
        </Card>

        <Card className="hover:bg-muted/50 transition-all cursor-pointer border-dashed">
          <CardContent className="pt-6 flex flex-col items-center justify-center text-center space-y-2">
            <div className="p-3 bg-emerald-500/10 rounded-full text-emerald-500">
              <PieChart className="h-6 w-6" />
            </div>
            <p className="font-semibold text-sm">Disponibilidade</p>
            <p className="text-xl font-bold">
              {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : `${(stats?.availability ?? 0).toFixed(1)}%`}
            </p>
          </CardContent>
        </Card>

        <Card className="hover:bg-muted/50 transition-all cursor-pointer border-dashed">
          <CardContent className="pt-6 flex flex-col items-center justify-center text-center space-y-2">
            <div className="p-3 bg-blue-500/10 rounded-full text-blue-500">
              <Activity className="h-6 w-6" />
            </div>
            <p className="font-semibold text-sm">Novos Ativos (Mês)</p>
            <p className="text-xl font-bold">
              {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : `+${stats?.newAssetsThisMonth ?? 0}`}
            </p>
          </CardContent>
        </Card>

        <Card className="hover:bg-muted/50 transition-all cursor-pointer border-dashed">
          <CardContent className="pt-6 flex flex-col items-center justify-center text-center space-y-2">
            <div className="p-3 bg-amber-500/10 rounded-full text-amber-500">
              <FileText className="h-6 w-6" />
            </div>
            <p className="font-semibold text-sm">Ações Pendentes</p>
            <p className="text-xl font-bold">
              {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : stats?.pendingActions ?? 0}
            </p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 md:grid-cols-3">
        <Card className="md:col-span-2">
          <CardHeader className="flex flex-row items-center justify-between">
            <div>
              <CardTitle>Modelos de Relatórios</CardTitle>
              <CardDescription>Escolha o modelo e exporte em múltiplos canais.</CardDescription>
            </div>
            <Button variant="ghost" size="icon">
              <Filter className="h-4 w-4" />
            </Button>
          </CardHeader>
          <CardContent className="p-0">
            <div className="divide-y">
              {reportTemplates.map((template) => (
                <div
                  key={template.key}
                  className={`p-4 flex items-center justify-between transition-colors group ${
                    selectedTemplate === template.key ? "bg-primary/5" : "hover:bg-muted/30"
                  }`}
                >
                  <div className="flex items-center gap-4">
                    <div className="p-2 bg-muted rounded group-hover:bg-primary/10 group-hover:text-primary transition-colors text-muted-foreground">
                      <FileText className="h-5 w-5" />
                    </div>
                    <div>
                      <p className="text-sm font-semibold">{template.title}</p>
                      <p className="text-xs text-muted-foreground">{template.desc}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <Badge variant="secondary" className="text-[10px] sm:flex hidden">
                      {template.type}
                    </Badge>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8"
                      onClick={() => {
                        setSelectedTemplate(template.key)
                        setIsExportModalOpen(true)
                      }}
                    >
                      <ArrowUpRight className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card className="bg-primary/5 border-primary/20">
          <CardHeader>
            <CardTitle className="text-primary">Entrega Premium</CardTitle>
            <CardDescription className="text-primary/70">
              Baixe ou envie por e-mail e WhatsApp em um clique.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <p className="text-xs font-semibold text-primary/80">Template selecionado</p>
              <Button variant="outline" className="w-full justify-between bg-white/50 border-primary/20 text-primary text-sm">
                {selectedTemplateMeta.title}
              </Button>
            </div>
            <div className="space-y-2">
              <p className="text-xs font-semibold text-primary/80">Canal</p>
              <Button variant="outline" className="w-full justify-between bg-white/50 border-primary/20 text-primary">
                {deliveryChannel === "DOWNLOAD" && (
                  <>
                    <Download className="mr-2 h-4 w-4" />
                    Download
                  </>
                )}
                {deliveryChannel === "EMAIL" && (
                  <>
                    <Mail className="mr-2 h-4 w-4" />
                    E-mail
                  </>
                )}
                {deliveryChannel === "WHATSAPP" && (
                  <>
                    <MessageCircle className="mr-2 h-4 w-4" />
                    WhatsApp
                  </>
                )}
              </Button>
            </div>
            <Button className="w-full shadow-md" onClick={() => setIsExportModalOpen(true)}>
              Configurar e enviar
            </Button>
          </CardContent>
        </Card>
      </div>

      <Modal isOpen={isExportModalOpen} onClose={() => setIsExportModalOpen(false)} title="Gerar Relatório Premium">
        <form className="space-y-4" onSubmit={handleExportSubmit}>
          <div className="space-y-2">
            <label className="text-sm font-medium" htmlFor="report-template">
              Modelo
            </label>
            <select
              id="report-template"
              className="h-10 w-full rounded-md border bg-background px-3 text-sm"
              value={selectedTemplate}
              onChange={(e) => setSelectedTemplate(e.target.value as ReportTemplateKey)}
            >
              {reportTemplates.map((template) => (
                <option key={template.key} value={template.key}>
                  {template.title}
                </option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="space-y-2">
              <label className="text-sm font-medium" htmlFor="report-format">
                Formato
              </label>
              <select
                id="report-format"
                className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                value={selectedFormat}
                onChange={(e) => setSelectedFormat(e.target.value as ReportFormat)}
              >
                <option value="PDF">PDF</option>
                <option value="XLSX">XLSX</option>
                <option value="CSV">CSV</option>
                <option value="JSON">JSON</option>
              </select>
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium" htmlFor="report-period">
                Período
              </label>
              <select
                id="report-period"
                className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                value={selectedPeriod}
                onChange={(e) => setSelectedPeriod(e.target.value as ReportPeriod)}
              >
                <option value="THIS_MONTH">Mês atual</option>
                <option value="LAST_7_DAYS">Últimos 7 dias</option>
                <option value="LAST_30_DAYS">Últimos 30 dias</option>
                <option value="LAST_90_DAYS">Últimos 90 dias</option>
                <option value="CUSTOM">Customizado</option>
              </select>
            </div>
          </div>

          {selectedPeriod === "CUSTOM" && (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium" htmlFor="report-custom-from">
                  Data inicial
                </label>
                <Input
                  id="report-custom-from"
                  type="date"
                  value={customFrom}
                  onChange={(e) => setCustomFrom(e.target.value)}
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium" htmlFor="report-custom-to">
                  Data final
                </label>
                <Input
                  id="report-custom-to"
                  type="date"
                  value={customTo}
                  onChange={(e) => setCustomTo(e.target.value)}
                />
              </div>
            </div>
          )}

          <div className="space-y-2">
            <label className="text-sm font-medium" htmlFor="report-delivery">
              Canal de entrega
            </label>
            <select
              id="report-delivery"
              className="h-10 w-full rounded-md border bg-background px-3 text-sm"
              value={deliveryChannel}
              onChange={(e) => setDeliveryChannel(e.target.value as DeliveryChannel)}
            >
              <option value="DOWNLOAD">Download imediato</option>
              <option value="EMAIL">Enviar por e-mail (anexo)</option>
              <option value="WHATSAPP">Enviar por WhatsApp (link seguro)</option>
            </select>
          </div>

          {deliveryChannel !== "DOWNLOAD" && (
            <div className="space-y-2">
              <label className="text-sm font-medium" htmlFor="report-recipient">
                Destinatário
              </label>
              <Input
                id="report-recipient"
                value={recipient}
                onChange={(e) => setRecipient(e.target.value)}
                placeholder={deliveryChannel === "EMAIL" ? "gestor@empresa.com" : "5565999999999"}
              />
            </div>
          )}

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="outline" onClick={() => setIsExportModalOpen(false)} disabled={exporting}>
              Cancelar
            </Button>
            <Button type="submit" disabled={exporting}>
              {exporting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Sparkles className="mr-2 h-4 w-4" />}
              Executar fluxo premium
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}
"use client"

import React from "react"
import {
  BarChart3,
  FileText,
  Download,
  ArrowUpRight,
  PieChart,
  Activity,
  Calendar,
  Filter,
  Loader2,
  Mail,
  MessageCircle,
  Sparkles,
} from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { Input } from "@/components/ui/input"

type ReportsStats = {
  monthlyCost: number
  availability: number
  newAssetsThisMonth: number
  pendingActions: number
  totalAssets: number
  assetsInMaintenance: number
  periodStart: string
}

type ReportTemplateKey =
  | "ASSET_INVENTORY"
  | "ASSET_DEPRECIATION"
  | "LICENSE_COMPLIANCE"
  | "MAINTENANCE_HISTORY"
  | "VAULT_AUDIT"

type ReportFormat = "PDF" | "XLSX" | "CSV" | "JSON"
type ReportPeriod = "THIS_MONTH" | "LAST_7_DAYS" | "LAST_30_DAYS" | "LAST_90_DAYS" | "CUSTOM"
type DeliveryChannel = "DOWNLOAD" | "EMAIL" | "WHATSAPP"

type ReportTemplateMeta = {
  key: ReportTemplateKey
  title: string
  desc: string
  type: string
}

const reportTemplates: ReportTemplateMeta[] = [
  {
    key: "ASSET_INVENTORY",
    title: "Inventario Geral de Ativos",
    desc: "Listagem completa de ativos, status e responsavel.",
    type: "PDF / XLSX / CSV / JSON",
  },
  {
    key: "ASSET_DEPRECIATION",
    title: "Depreciacao de Equipamentos",
    desc: "Estimativa de valor contabil por tempo de uso.",
    type: "PDF / XLSX / CSV / JSON",
  },
  {
    key: "LICENSE_COMPLIANCE",
    title: "Relatorio de Licenciamento",
    desc: "Conformidade de inventario de software e SO.",
    type: "PDF / XLSX / CSV / JSON",
  },
  {
    key: "MAINTENANCE_HISTORY",
    title: "Historico de Manutencoes",
    desc: "Custos, tecnicos e progresso no periodo.",
    type: "PDF / XLSX / CSV / JSON",
  },
  {
    key: "VAULT_AUDIT",
    title: "Log de Acesso ao Cofre",
    desc: "Auditoria de visualizacao e copia de credenciais.",
    type: "PDF / XLSX / CSV / JSON",
  },
]

function formatCurrencyBRL(value: number) {
  return new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
    maximumFractionDigits: 0,
  }).format(value)
}

function inferFilename(disposition: string | null, fallback: string) {
  if (!disposition) return fallback
  const match = disposition.match(/filename="(.+?)"/i)
  return match?.[1] || fallback
}

export default function ReportsPage() {
  const [stats, setStats] = React.useState<ReportsStats | null>(null)
  const [loading, setLoading] = React.useState(true)
  const [error, setError] = React.useState<string | null>(null)

  const [selectedTemplate, setSelectedTemplate] = React.useState<ReportTemplateKey>("ASSET_INVENTORY")
  const [selectedFormat, setSelectedFormat] = React.useState<ReportFormat>("PDF")
  const [selectedPeriod, setSelectedPeriod] = React.useState<ReportPeriod>("THIS_MONTH")
  const [deliveryChannel, setDeliveryChannel] = React.useState<DeliveryChannel>("DOWNLOAD")
  const [recipient, setRecipient] = React.useState("")
  const [customFrom, setCustomFrom] = React.useState("")
  const [customTo, setCustomTo] = React.useState("")
  const [isExportModalOpen, setIsExportModalOpen] = React.useState(false)
  const [exporting, setExporting] = React.useState(false)
  const [actionMessage, setActionMessage] = React.useState<string | null>(null)
  const [actionError, setActionError] = React.useState<string | null>(null)
  const [lastDeliveryUrl, setLastDeliveryUrl] = React.useState<string | null>(null)

  React.useEffect(() => {
    async function loadStats() {
      try {
        setError(null)
        const res = await fetch("/api/reports/stats")
        if (!res.ok) {
          const data = (await res.json().catch(() => ({}))) as { error?: string }
          throw new Error(data.error || "Falha ao carregar indicadores")
        }

        const data = (await res.json()) as ReportsStats
        setStats(data)
      } catch (err) {
        setError(err instanceof Error ? err.message : "Erro inesperado")
      } finally {
        setLoading(false)
      }
    }

    loadStats()
  }, [])

  const periodLabel = stats
    ? new Date(stats.periodStart).toLocaleDateString("pt-BR", {
        month: "long",
        year: "numeric",
      })
    : new Date().toLocaleDateString("pt-BR", { month: "long", year: "numeric" })

  const selectedTemplateMeta = reportTemplates.find((template) => template.key === selectedTemplate) || reportTemplates[0]

  async function handleExportSubmit(e: React.FormEvent) {
    e.preventDefault()
    setExporting(true)
    setActionMessage(null)
    setActionError(null)
    setLastDeliveryUrl(null)

    try {
      if (deliveryChannel !== "DOWNLOAD" && !recipient.trim()) {
        throw new Error("Informe o destinatario para envio.")
      }

      if (selectedPeriod === "CUSTOM" && (!customFrom || !customTo)) {
        throw new Error("Informe a data inicial e final para periodo customizado.")
      }

      const payload = {
        template: selectedTemplate,
        format: selectedFormat,
        period: selectedPeriod,
        delivery: deliveryChannel,
        recipient: deliveryChannel === "DOWNLOAD" ? undefined : recipient.trim(),
        fromDate: selectedPeriod === "CUSTOM" ? customFrom : undefined,
        toDate: selectedPeriod === "CUSTOM" ? customTo : undefined,
      }

      const response = await fetch("/api/reports/export", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      })

      if (!response.ok) {
        const text = await response.text()
        try {
          const asJson = JSON.parse(text) as { error?: string }
          throw new Error(asJson.error || "Falha na exportacao")
        } catch {
          throw new Error(text || "Falha na exportacao")
        }
      }

      if (deliveryChannel === "DOWNLOAD") {
        const blob = await response.blob()
        const filename = inferFilename(
          response.headers.get("content-disposition"),
          `relatorio.${selectedFormat.toLowerCase()}`
        )
        const url = window.URL.createObjectURL(blob)
        const a = document.createElement("a")
        a.href = url
        a.download = filename
        document.body.appendChild(a)
        a.click()
        a.remove()
        window.URL.revokeObjectURL(url)

        setActionMessage(`Relatorio gerado com sucesso (${filename}).`)
      } else {
        const data = (await response.json()) as { message?: string; downloadUrl?: string }
        setActionMessage(data.message || "Relatorio enviado com sucesso.")
        setLastDeliveryUrl(data.downloadUrl || null)
      }
    } catch (err) {
      setActionError(err instanceof Error ? err.message : "Erro inesperado")
    } finally {
      setExporting(false)
      setIsExportModalOpen(false)
    }
  }

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Relatorios e BI</h1>
          <p className="text-muted-foreground">
            Analise dados reais da infraestrutura e gere documentos premium.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline">
            <Calendar className="mr-2 h-4 w-4" />
            {periodLabel}
          </Button>
          <Button className="bg-primary" onClick={() => setIsExportModalOpen(true)}>
            <Sparkles className="mr-2 h-4 w-4" />
            Gerar Relatorio Premium
          </Button>
        </div>
      </div>

      {error && (
        <Card className="border-destructive/30 bg-destructive/5">
          <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
        </Card>
      )}

      {actionMessage && (
        <Card className="border-emerald-500/40 bg-emerald-500/5">
          <CardContent className="pt-6 text-sm text-emerald-700">
            {actionMessage}
            {lastDeliveryUrl && (
              <div className="mt-2 break-all">
                Link:{" "}
                <a href={lastDeliveryUrl} target="_blank" rel="noreferrer" className="underline">
                  {lastDeliveryUrl}
                </a>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {actionError && (
        <Card className="border-destructive/30 bg-destructive/5">
          <CardContent className="pt-6 text-sm text-destructive">{actionError}</CardContent>
        </Card>
      )}

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <Card className="hover:bg-muted/50 transition-all cursor-pointer border-dashed">
          <CardContent className="pt-6 flex flex-col items-center justify-center text-center space-y-2">
            <div className="p-3 bg-primary/10 rounded-full text-primary">
              <BarChart3 className="h-6 w-6" />
            </div>
            <p className="font-semibold text-sm">Custo Mensal</p>
            <p className="text-xl font-bold">
              {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : formatCurrencyBRL(stats?.monthlyCost ?? 0)}
            </p>
          </CardContent>
        </Card>

        <Card className="hover:bg-muted/50 transition-all cursor-pointer border-dashed">
          <CardContent className="pt-6 flex flex-col items-center justify-center text-center space-y-2">
            <div className="p-3 bg-emerald-500/10 rounded-full text-emerald-500">
              <PieChart className="h-6 w-6" />
            </div>
            <p className="font-semibold text-sm">Disponibilidade</p>
            <p className="text-xl font-bold">
              {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : `${(stats?.availability ?? 0).toFixed(1)}%`}
            </p>
          </CardContent>
        </Card>

        <Card className="hover:bg-muted/50 transition-all cursor-pointer border-dashed">
          <CardContent className="pt-6 flex flex-col items-center justify-center text-center space-y-2">
            <div className="p-3 bg-blue-500/10 rounded-full text-blue-500">
              <Activity className="h-6 w-6" />
            </div>
            <p className="font-semibold text-sm">Novos Ativos (Mes)</p>
            <p className="text-xl font-bold">
              {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : `+${stats?.newAssetsThisMonth ?? 0}`}
            </p>
          </CardContent>
        </Card>

        <Card className="hover:bg-muted/50 transition-all cursor-pointer border-dashed">
          <CardContent className="pt-6 flex flex-col items-center justify-center text-center space-y-2">
            <div className="p-3 bg-amber-500/10 rounded-full text-amber-500">
              <FileText className="h-6 w-6" />
            </div>
            <p className="font-semibold text-sm">Acoes Pendentes</p>
            <p className="text-xl font-bold">
              {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : stats?.pendingActions ?? 0}
            </p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 md:grid-cols-3">
        <Card className="md:col-span-2">
          <CardHeader className="flex flex-row items-center justify-between">
            <div>
              <CardTitle>Modelos de Relatorios</CardTitle>
              <CardDescription>Escolha o modelo e exporte em multiplos canais.</CardDescription>
            </div>
            <Button variant="ghost" size="icon">
              <Filter className="h-4 w-4" />
            </Button>
          </CardHeader>
          <CardContent className="p-0">
            <div className="divide-y">
              {reportTemplates.map((template) => (
                <div
                  key={template.key}
                  className={`p-4 flex items-center justify-between transition-colors group ${
                    selectedTemplate === template.key ? "bg-primary/5" : "hover:bg-muted/30"
                  }`}
                >
                  <div className="flex items-center gap-4">
                    <div className="p-2 bg-muted rounded group-hover:bg-primary/10 group-hover:text-primary transition-colors text-muted-foreground">
                      <FileText className="h-5 w-5" />
                    </div>
                    <div>
                      <p className="text-sm font-semibold">{template.title}</p>
                      <p className="text-xs text-muted-foreground">{template.desc}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <Badge variant="secondary" className="text-[10px] sm:flex hidden">
                      {template.type}
                    </Badge>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8"
                      onClick={() => {
                        setSelectedTemplate(template.key)
                        setIsExportModalOpen(true)
                      }}
                    >
                      <ArrowUpRight className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card className="bg-primary/5 border-primary/20">
          <CardHeader>
            <CardTitle className="text-primary">Entrega Premium</CardTitle>
            <CardDescription className="text-primary/70">
              Baixe ou envie por e-mail e WhatsApp em um clique.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <p className="text-xs font-semibold text-primary/80">Template selecionado</p>
              <Button variant="outline" className="w-full justify-between bg-white/50 border-primary/20 text-primary text-sm">
                {selectedTemplateMeta.title}
              </Button>
            </div>
            <div className="space-y-2">
              <p className="text-xs font-semibold text-primary/80">Canal</p>
              <Button variant="outline" className="w-full justify-between bg-white/50 border-primary/20 text-primary">
                {deliveryChannel === "DOWNLOAD" && (
                  <>
                    <Download className="mr-2 h-4 w-4" />
                    Download
                  </>
                )}
                {deliveryChannel === "EMAIL" && (
                  <>
                    <Mail className="mr-2 h-4 w-4" />
                    E-mail
                  </>
                )}
                {deliveryChannel === "WHATSAPP" && (
                  <>
                    <MessageCircle className="mr-2 h-4 w-4" />
                    WhatsApp
                  </>
                )}
              </Button>
            </div>
            <Button className="w-full shadow-md" onClick={() => setIsExportModalOpen(true)}>
              Configurar e enviar
            </Button>
          </CardContent>
        </Card>
      </div>

      <Modal isOpen={isExportModalOpen} onClose={() => setIsExportModalOpen(false)} title="Gerar Relatorio Premium">
        <form className="space-y-4" onSubmit={handleExportSubmit}>
          <div className="space-y-2">
            <label className="text-sm font-medium" htmlFor="report-template">
              Modelo
            </label>
            <select
              id="report-template"
              className="h-10 w-full rounded-md border bg-background px-3 text-sm"
              value={selectedTemplate}
              onChange={(e) => setSelectedTemplate(e.target.value as ReportTemplateKey)}
            >
              {reportTemplates.map((template) => (
                <option key={template.key} value={template.key}>
                  {template.title}
                </option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="space-y-2">
              <label className="text-sm font-medium" htmlFor="report-format">
                Formato
              </label>
              <select
                id="report-format"
                className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                value={selectedFormat}
                onChange={(e) => setSelectedFormat(e.target.value as ReportFormat)}
              >
                <option value="PDF">PDF</option>
                <option value="XLSX">XLSX</option>
                <option value="CSV">CSV</option>
                <option value="JSON">JSON</option>
              </select>
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium" htmlFor="report-period">
                Periodo
              </label>
              <select
                id="report-period"
                className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                value={selectedPeriod}
                onChange={(e) => setSelectedPeriod(e.target.value as ReportPeriod)}
              >
                <option value="THIS_MONTH">Mes atual</option>
                <option value="LAST_7_DAYS">Ultimos 7 dias</option>
                <option value="LAST_30_DAYS">Ultimos 30 dias</option>
                <option value="LAST_90_DAYS">Ultimos 90 dias</option>
                <option value="CUSTOM">Customizado</option>
              </select>
            </div>
          </div>

          {selectedPeriod === "CUSTOM" && (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium" htmlFor="report-custom-from">
                  Data inicial
                </label>
                <Input
                  id="report-custom-from"
                  type="date"
                  value={customFrom}
                  onChange={(e) => setCustomFrom(e.target.value)}
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium" htmlFor="report-custom-to">
                  Data final
                </label>
                <Input
                  id="report-custom-to"
                  type="date"
                  value={customTo}
                  onChange={(e) => setCustomTo(e.target.value)}
                />
              </div>
            </div>
          )}

          <div className="space-y-2">
            <label className="text-sm font-medium" htmlFor="report-delivery">
              Canal de entrega
            </label>
            <select
              id="report-delivery"
              className="h-10 w-full rounded-md border bg-background px-3 text-sm"
              value={deliveryChannel}
              onChange={(e) => setDeliveryChannel(e.target.value as DeliveryChannel)}
            >
              <option value="DOWNLOAD">Download imediato</option>
              <option value="EMAIL">Enviar por e-mail (anexo)</option>
              <option value="WHATSAPP">Enviar por WhatsApp (link seguro)</option>
            </select>
          </div>

          {deliveryChannel !== "DOWNLOAD" && (
            <div className="space-y-2">
              <label className="text-sm font-medium" htmlFor="report-recipient">
                Destinatario
              </label>
              <Input
                id="report-recipient"
                value={recipient}
                onChange={(e) => setRecipient(e.target.value)}
                placeholder={deliveryChannel === "EMAIL" ? "gestor@empresa.com" : "5565999999999"}
              />
            </div>
          )}

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="outline" onClick={() => setIsExportModalOpen(false)} disabled={exporting}>
              Cancelar
            </Button>
            <Button type="submit" disabled={exporting}>
              {exporting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Sparkles className="mr-2 h-4 w-4" />}
              Executar fluxo premium
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}
