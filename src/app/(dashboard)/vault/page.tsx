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

