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
import { TicketForm } from "@/components/features/tickets/TicketForm"

const PRIORITY_STYLE: Record<string, string> = {
  BAIXA: "bg-zinc-500/10 text-zinc-400 border-zinc-500/20",
  MEDIA: "bg-blue-500/10 text-blue-500 border-blue-500/20",
  ALTA: "bg-amber-500/10 text-amber-500 border-amber-500/20",
  CRITICA: "bg-red-500/10 text-red-500 border-red-500/20",
}

export default function TicketsPage() {
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
        fetchData()
      }
    } catch (error) {
      console.error("Error saving ticket:", error)
    }
  }

  async function handleDelete(id: string) {
    if (!confirm("Deseja realmente excluir este chamado?")) return
    try {
      const res = await fetch(`/api/tickets/${id}`, { method: "DELETE" })
      if (res.ok) fetchData()
    } catch (error) {
      console.error("Error deleting ticket:", error)
    }
  }

  const openCount = tickets.filter(t => t.status !== "CONCLUIDO").length
  const criticalOpenCount = tickets.filter(t => t.status !== "CONCLUIDO" && t.priority === "CRITICA").length
  const closedCount = tickets.filter(t => t.status === "CONCLUIDO").length

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

      <div className="grid gap-6 md:grid-cols-3">
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
