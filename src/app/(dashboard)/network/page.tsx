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

