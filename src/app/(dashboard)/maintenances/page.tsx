"use client"

import React from "react"
import {
  Wrench,
  History,
  Clock,
  CheckCircle2,
  Plus,
  Loader2,
  Pencil,
  Trash2
} from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { cn } from "@/lib/utils"
import { MaintenanceForm } from "@/components/features/maintenances/MaintenanceForm"
import { useToast } from "@/components/toast-provider"
import { useConfirm } from "@/components/confirm-dialog-provider"

const STATUS_STYLE: Record<string, string> = {
  PENDENTE: "bg-amber-500/10 text-amber-500 border-amber-500/20",
  EM_PROGRESSO: "bg-blue-500/10 text-blue-500 border-blue-500/20",
  CONCLUIDO: "bg-emerald-500/10 text-emerald-500 border-emerald-500/20",
  CANCELADO: "bg-zinc-500/10 text-zinc-400 border-zinc-500/20",
}

export default function MaintenancePage() {
  const [maintenances, setMaintenances] = React.useState<any[]>([])
  const [assets, setAssets] = React.useState<any[]>([])
  const [loading, setLoading] = React.useState(true)
  const [isModalOpen, setIsModalOpen] = React.useState(false)
  const [editingMaint, setEditingMaint] = React.useState<any>(null)
  const { success, error: toastError } = useToast()
  const confirmDialog = useConfirm()

  const fetchData = React.useCallback(async () => {
    setLoading(true)
    try {
      const [mRes, aRes] = await Promise.all([
        fetch("/api/maintenances"),
        fetch("/api/assets")
      ])
      const mData = await mRes.json()
      const aData = await aRes.json()

      if (Array.isArray(mData)) setMaintenances(mData)
      if (Array.isArray(aData)) setAssets(aData)
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
    const url = editingMaint ? `/api/maintenances/${editingMaint.id}` : "/api/maintenances"
    const method = editingMaint ? "PUT" : "POST"

    try {
      const res = await fetch(url, {
        method,
        body: JSON.stringify(data),
        headers: { "Content-Type": "application/json" }
      })

      if (res.ok) {
        success(editingMaint ? "Manutenção atualizada com sucesso" : "Manutenção registrada com sucesso")
        setIsModalOpen(false)
        setEditingMaint(null)
        fetchData()
      } else {
        const result = await res.json().catch(() => null)
        toastError(result?.error || "Erro ao salvar manutenção")
      }
    } catch (error) {
      console.error("Error saving maintenance:", error)
      toastError("Erro ao salvar manutenção")
    }
  }

  async function handleDelete(id: string) {
    const confirmed = await confirmDialog({
      title: "Excluir Manutenção",
      description: "Deseja realmente excluir este registro de manutenção? Esta ação não pode ser desfeita.",
      confirmLabel: "Excluir",
      cancelLabel: "Cancelar",
    })
    if (!confirmed) return

    try {
      const res = await fetch(`/api/maintenances/${id}`, { method: "DELETE" })
      if (res.ok) {
        success("Manutenção excluída com sucesso")
        fetchData()
      } else {
        const result = await res.json().catch(() => null)
        toastError(result?.error || "Erro ao excluir manutenção")
      }
    } catch (error) {
      console.error("Error deleting maintenance:", error)
      toastError("Erro ao excluir manutenção")
    }
  }

  const pendingCount = maintenances.filter(m => m.status === "PENDENTE").length
  const inProgressCount = maintenances.filter(m => m.status === "EM_PROGRESSO").length
  const completedCount = maintenances.filter(m => m.status === "CONCLUIDO").length

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Manutenções e Chamados</h1>
          <p className="text-muted-foreground">Gerenciamento de intervenções técnicas e histórico de reparos.</p>
        </div>
        <Button className="bg-primary shadow-lg shadow-primary/20" onClick={() => { setEditingMaint(null); setIsModalOpen(true); }}>
          <Plus className="mr-2 h-4 w-4" />
          Registrar Manutenção
        </Button>
      </div>

      <div className="grid gap-6 md:grid-cols-3">
        <Card className="bg-amber-500/5 border-amber-500/20">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Clock className="h-4 w-4 text-amber-500" />
              Aguardando Início
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{String(pendingCount).padStart(2, '0')}</div>
            <p className="text-xs text-muted-foreground mt-1 text-amber-600/80">Requer atenção técnica</p>
          </CardContent>
        </Card>
        <Card className="bg-blue-500/5 border-blue-500/20">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Wrench className="h-4 w-4 text-blue-500" />
              Em Execução
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{String(inProgressCount).padStart(2, '0')}</div>
            <p className="text-xs text-muted-foreground mt-1 text-blue-600/80">Ativos em bancada</p>
          </CardContent>
        </Card>
        <Card className="bg-emerald-500/5 border-emerald-500/20">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <CheckCircle2 className="h-4 w-4 text-emerald-500" />
              Concluídas
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{String(completedCount).padStart(2, '0')}</div>
            <p className="text-xs text-muted-foreground mt-1 text-emerald-600/80">Histórico de sucesso</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Timeline de Atividades</CardTitle>
            <CardDescription>Eventos de manutenção registrados no sistema.</CardDescription>
          </div>
          <Button variant="outline" size="sm" onClick={fetchData} disabled={loading}>
            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <History className="mr-2 h-4 w-4" />}
            Sincronizar
          </Button>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y relative min-h-[400px]">
            {loading ? (
              <div className="absolute inset-0 flex items-center justify-center bg-background/50 backdrop-blur-[1px]">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
              </div>
            ) : maintenances.length === 0 ? (
              <div className="p-12 text-center text-muted-foreground">
                Nenhum registro de manutenção encontrado no banco de dados.
              </div>
            ) : (
              maintenances.map((mnt) => (
                <div key={mnt.id} className="p-4 hover:bg-muted/50 transition-colors flex items-center justify-between group">
                  <div className="flex items-center gap-4">
                    <div className={cn(
                      "p-2 rounded-full",
                      mnt.status === "CONCLUIDO" ? "bg-emerald-500/10 text-emerald-500" :
                      mnt.status === "CANCELADO" ? "bg-muted text-muted-foreground" : "bg-amber-500/10 text-amber-500"
                    )}>
                      {mnt.status === "CONCLUIDO" ? <CheckCircle2 className="h-5 w-5" /> : <Clock className="h-5 w-5" />}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <p className="font-semibold text-sm">{mnt.problem}</p>
                        <span className="text-muted-foreground opacity-30">•</span>
                        <p className="text-sm font-medium text-primary">{mnt.asset?.name || "Ativo Desconhecido"}</p>
                        <Badge variant="outline" className={cn("text-[10px] font-normal py-0 h-4", STATUS_STYLE[mnt.status])}>
                          {mnt.status}
                        </Badge>
                      </div>
                      <p className="text-xs text-muted-foreground mt-1">
                        Registrado em {new Date(mnt.startDate).toLocaleDateString()} por {mnt.technician}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="hidden md:flex flex-col items-end mr-4">
                      <p className="text-[10px] uppercase font-bold text-muted-foreground">Custo</p>
                      <p className="text-xs font-semibold text-emerald-600">
                        {mnt.cost ? `R$ ${mnt.cost.toFixed(2)}` : "N/A"}
                      </p>
                    </div>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 text-muted-foreground hover:text-primary"
                      aria-label="Editar manutenção"
                      onClick={() => { setEditingMaint(mnt); setIsModalOpen(true); }}
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 text-destructive hover:text-destructive"
                      aria-label="Excluir manutenção"
                      onClick={() => handleDelete(mnt.id)}
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
        title={editingMaint ? "Editar Manutenção" : "Nova Manutenção"}
      >
        <MaintenanceForm
          initialData={editingMaint}
          assets={assets}
          onCancel={() => setIsModalOpen(false)}
          onSubmit={handleCreateOrUpdate}
        />
      </Modal>
    </div>
  )
}
