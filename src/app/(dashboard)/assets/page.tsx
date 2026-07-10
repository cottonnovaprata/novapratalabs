"use client"

import React from "react"
import Link from "next/link"
import {
  Plus,
  Search,
  Download,
  Laptop,
  Smartphone,
  Server,
  Monitor,
  Pencil,
  Trash2,
  Loader2,
  Wrench
} from "lucide-react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { AssetForm } from "@/components/features/assets/AssetForm"
import { AssetMaintenanceHistory } from "@/components/features/assets/AssetMaintenanceHistory"
import { useToast } from "@/components/toast-provider"
import { useConfirm } from "@/components/confirm-dialog-provider"

export default function AssetsPage() {
  const [assets, setAssets] = React.useState<any[]>([])
  const [sectors, setSectors] = React.useState<any[]>([])
  const [loading, setLoading] = React.useState(true)
  const [isModalOpen, setIsModalOpen] = React.useState(false)
  const [editingAsset, setEditingAsset] = React.useState<any>(null)
  const [searchTerm, setSearchTerm] = React.useState("")
  const [historyAsset, setHistoryAsset] = React.useState<any>(null)
  const [isHistoryOpen, setIsHistoryOpen] = React.useState(false)
  const { success, error: toastError } = useToast()
  const confirmDialog = useConfirm()

  const fetchData = React.useCallback(async () => {
    setLoading(true)
    try {
      const [assetsRes, sectorsRes] = await Promise.all([
        fetch("/api/assets"),
        fetch("/api/sectors")
      ])
      const assetsData = await assetsRes.json()
      const sectorsData = await sectorsRes.json()

      if (Array.isArray(assetsData)) setAssets(assetsData)
      if (Array.isArray(sectorsData)) setSectors(sectorsData)
    } catch (error) {
      console.error("Error fetching data:", error)
    } finally {
      setLoading(false)
    }
  }, [])

  React.useEffect(() => {
    fetchData()
  }, [fetchData])

  async function handleCreateOrUpdate(data: any) {
    const url = editingAsset ? `/api/assets/${editingAsset.id}` : "/api/assets"
    const method = editingAsset ? "PUT" : "POST"

    try {
      const res = await fetch(url, {
        method,
        body: JSON.stringify(data),
        headers: { "Content-Type": "application/json" }
      })

      if (res.ok) {
        success(editingAsset ? "Ativo atualizado com sucesso" : "Ativo cadastrado com sucesso")
        setIsModalOpen(false)
        setEditingAsset(null)
        fetchData()
      } else {
        const result = await res.json().catch(() => null)
        toastError(result?.error || "Erro ao salvar ativo")
      }
    } catch (error) {
      console.error("Error saving asset:", error)
      toastError("Erro ao salvar ativo")
    }
  }

  async function handleDelete(id: string) {
    const confirmed = await confirmDialog({
      title: "Excluir Ativo",
      message: "Deseja realmente excluir este ativo? Esta ação não pode ser desfeita.",
      confirmLabel: "Excluir",
      destructive: true,
    })
    if (!confirmed) return

    try {
      const res = await fetch(`/api/assets/${id}`, { method: "DELETE" })
      if (res.ok) {
        success("Ativo excluído com sucesso")
        fetchData()
      } else {
        const result = await res.json().catch(() => null)
        toastError(result?.error || "Erro ao excluir ativo")
      }
    } catch (error) {
      console.error("Error deleting asset:", error)
      toastError("Erro ao excluir ativo")
    }
  }

  const filteredAssets = assets.filter(asset =>
    asset.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    asset.tag.toLowerCase().includes(searchTerm.toLowerCase()) ||
    asset.brand.toLowerCase().includes(searchTerm.toLowerCase())
  )

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-2 duration-500">
      <div className="flex flex-col gap-5 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex-1">
          <h1 className="text-3xl sm:text-4xl font-bold tracking-tight" style={{color: "var(--text-primary)"}}>Ativos de TI</h1>
          <p className="text-sm mt-2" style={{color: "var(--text-tertiary)"}}>Gerencie todos os seus equipamentos</p>
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          <Button variant="outline" onClick={fetchData} disabled={loading} size="sm">
            {loading ? <Loader2 className="mr-1.5 h-4 w-4 animate-spin" /> : <Download className="mr-1.5 h-4 w-4" />}
            <span className="hidden sm:inline">Sincronizar</span>
            <span className="sm:hidden">Sync</span>
          </Button>
          <Button onClick={() => { setEditingAsset(null); setIsModalOpen(true); }} size="sm">
            <Plus className="mr-1.5 h-4 w-4" />
            <span className="hidden sm:inline">Novo Ativo</span>
            <span className="sm:hidden">Novo</span>
          </Button>
        </div>
      </div>

      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-zinc-500" />
        <Input
          placeholder="Buscar por nome, marca ou patrimônio..."
          className="pl-10"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          style={{color: "var(--input-text)"}}
        />
      </div>

      <Card>
        <CardContent className="p-0">
          <div className="relative w-full overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr style={{borderColor: "var(--border-primary)", borderBottom: "2px solid var(--border-secondary)", background: "var(--bg-muted)"}}>
                  <th className="h-13 px-4 text-left align-middle font-bold text-xs" style={{color: "var(--text-secondary)"}}>Equipamento</th>
                  <th className="h-13 px-4 text-left align-middle font-bold text-xs hidden sm:table-cell" style={{color: "var(--text-secondary)"}}>Tipo</th>
                  <th className="h-13 px-4 text-left align-middle font-bold text-xs" style={{color: "var(--text-secondary)"}}>Status</th>
                  <th className="h-13 px-4 text-left align-middle font-bold text-xs hidden md:table-cell" style={{color: "var(--text-secondary)"}}>Setor</th>
                  <th className="h-13 px-4 text-left align-middle font-bold text-xs hidden lg:table-cell" style={{color: "var(--text-secondary)"}}>Criticidade</th>
                  <th className="h-13 px-4 align-middle font-bold text-xs text-right" style={{color: "var(--text-secondary)"}}>Ações</th>
                </tr>
              </thead>
              <tbody className="[&_tr:last-child]:border-0">
                {loading ? (
                  <tr>
                    <td colSpan={6} className="p-8 text-center">
                      <Loader2 className="h-8 w-8 animate-spin mx-auto mb-2 text-primary" />
                      <p className="text-sm" style={{color: "var(--text-tertiary)"}}>Carregando...</p>
                    </td>
                  </tr>
                ) : filteredAssets.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="p-8 text-center" style={{color: "var(--text-tertiary)"}}>
                      Nenhum ativo encontrado
                    </td>
                  </tr>
                ) : filteredAssets.map((asset) => (
                  <tr key={asset.id} className="transition-all duration-200 group cursor-pointer" style={{borderBottom: `1px solid var(--border-primary)`}} onMouseEnter={(e) => {e.currentTarget.style.background = "var(--bg-hover)"}} onMouseLeave={(e) => {e.currentTarget.style.background = "transparent"}}>
                    <td className="p-5 align-middle">
                      <Link href={`/assets/${asset.id}`} className="flex items-center gap-3">
                        <div className="h-9 w-9 rounded-lg flex items-center justify-center flex-shrink-0" style={{background: "var(--bg-tertiary)", color: "var(--text-tertiary)"}}>
                          {asset.type === "Notebook" && <Laptop className="h-4 w-4" />}
                          {asset.type === "Smartphone" && <Smartphone className="h-4 w-4" />}
                          {asset.type === "Servidor" && <Server className="h-4 w-4" />}
                          {asset.type === "Monitor" && <Monitor className="h-4 w-4" />}
                          {!["Notebook", "Smartphone", "Servidor", "Monitor"].includes(asset.type) && <Monitor className="h-4 w-4 opacity-40" />}
                        </div>
                        <div className="min-w-0">
                          <p className="font-semibold truncate" style={{color: "var(--text-primary)"}}>{asset.name}</p>
                          <p className="text-xs truncate mt-0.5" style={{color: "var(--text-tertiary)"}}>{asset.tag}</p>
                        </div>
                      </Link>
                    </td>
                    <td className="p-5 align-middle text-xs hidden sm:table-cell" style={{color: "var(--text-secondary)"}}>{asset.type}</td>
                    <td className="p-5 align-middle">
                      <Badge
                        variant={asset.status === "DISPONIVEL" ? "success" : asset.status === "EM_USO" ? "default" : "warning"}
                        className="text-xs font-semibold"
                      >
                        {asset.status === "DISPONIVEL" ? "Disponível" : asset.status === "EM_USO" ? "Em Uso" : asset.status}
                      </Badge>
                    </td>
                    <td className="p-5 align-middle text-xs hidden md:table-cell" style={{color: "var(--text-secondary)"}}>
                      {asset.sector?.name || "—"}
                    </td>
                    <td className="p-5 align-middle text-xs font-semibold hidden lg:table-cell" style={{color: "var(--text-secondary)"}}>
                      {asset.criticality}
                    </td>
                    <td className="p-5 align-middle text-right">
                      <div className="flex justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-7 w-7 text-zinc-400 hover:text-blue-400 hover:bg-blue-500/10"
                          aria-label="Ver histórico de manutenção"
                          onClick={() => { setHistoryAsset(asset); setIsHistoryOpen(true); }}
                        >
                          <Wrench className="h-3.5 w-3.5" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-7 w-7 text-zinc-400 hover:text-primary hover:bg-primary/10"
                          aria-label="Editar ativo"
                          onClick={() => { setEditingAsset(asset); setIsModalOpen(true); }}
                        >
                          <Pencil className="h-3.5 w-3.5" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-7 w-7 text-zinc-400 hover:text-red-400 hover:bg-red-500/10"
                          aria-label="Excluir ativo"
                          onClick={() => handleDelete(asset.id)}
                        >
                          <Trash2 className="h-3.5 w-3.5" />
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
        title={editingAsset ? "Editar Ativo" : "Novo Ativo"}
      >
        <AssetForm
          initialData={editingAsset}
          sectors={sectors}
          onCancel={() => setIsModalOpen(false)}
          onSubmit={handleCreateOrUpdate}
        />
      </Modal>

      <Modal
        isOpen={isHistoryOpen}
        onClose={() => setIsHistoryOpen(false)}
        title={`Histórico - ${historyAsset?.name || "Ativo"}`}
      >
        {historyAsset && <AssetMaintenanceHistory assetId={historyAsset.id} />}
        <div className="mt-6 pt-4 border-t flex justify-end">
          <Button variant="outline" onClick={() => setIsHistoryOpen(false)}>Fechar</Button>
        </div>
      </Modal>
    </div>
  )
}
