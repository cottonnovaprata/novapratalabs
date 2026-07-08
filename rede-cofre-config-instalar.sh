#!/usr/bin/env bash
set -e
echo "Escrevendo arquivos..."
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
      await fetchOverview()
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro inesperado")
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
    if (!confirm("Deseja realmente excluir esta VLAN/segmento?")) return
    try {
      const res = await fetch(`/api/network/segments/${id}`, { method: "DELETE" })
      const data = (await res.json().catch(() => ({}))) as { error?: string }
      if (!res.ok) {
        throw new Error(data.error || "Erro ao excluir segmento")
      }
      await fetchOverview()
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro inesperado")
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
      await fetchData()
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro inesperado")
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
    if (!confirm("Deseja realmente excluir esta credencial? Essa acao nao pode ser desfeita.")) return
    try {
      const res = await fetch(`/api/vault/credentials/${id}`, { method: "DELETE" })
      const data = (await res.json().catch(() => ({}))) as { error?: string }
      if (!res.ok) {
        throw new Error(data.error || "Erro ao excluir credencial")
      }
      await fetchData()
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro inesperado")
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
echo "Arquivos escritos com sucesso."
echo "Agora rode:"
echo "  npm install"
echo "  npx prisma generate"
echo "  npm run build"
