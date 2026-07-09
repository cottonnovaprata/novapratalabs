"use client"

import React from "react"
import Link from "next/link"
import { Search, UserPlus, Loader2, RefreshCcw, MapPin, Package } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { useConfirm } from "@/components/confirm-dialog-provider"
import { useToast } from "@/components/toast-provider"
import { ProducerForm } from "@/components/features/producers/ProducerForm"

function initials(name: string) {
  return name.split(" ").filter(Boolean).slice(0, 2).map(p => p[0]).join("").toUpperCase()
}

function statusVariant(status: string) {
  if (status === "ativo") return "success"
  if (status === "pendente") return "warning"
  return "outline"
}

export default function ProducersPage() {
  const confirmDialog = useConfirm()
  const { success, error: toastError } = useToast()
  const [producers, setProducers] = React.useState<any[]>([])
  const [loading, setLoading] = React.useState(true)
  const [searchTerm, setSearchTerm] = React.useState("")
  const [isModalOpen, setIsModalOpen] = React.useState(false)
  const [editingProducer, setEditingProducer] = React.useState<any>(null)
  const [error, setError] = React.useState<string | null>(null)

  const fetchProducers = React.useCallback(async () => {
    setLoading(true)
    try {
      const res = await fetch("/api/producers")
      const data = await res.json()
      if (Array.isArray(data)) setProducers(data)
    } catch (error) {
      console.error("Error fetching producers:", error)
    } finally {
      setLoading(false)
    }
  }, [])

  React.useEffect(() => { fetchProducers() }, [fetchProducers])

  async function handleCreateOrUpdate(data: any) {
    setError(null)
    const url = editingProducer ? `/api/producers/${editingProducer.id}` : "/api/producers"
    const method = editingProducer ? "PUT" : "POST"
    try {
      const res = await fetch(url, {
        method,
        body: JSON.stringify(data),
        headers: { "Content-Type": "application/json" },
      })
      const result = await res.json()
      if (res.ok) {
        setIsModalOpen(false)
        setEditingProducer(null)
        success(editingProducer ? "Produtor atualizado" : "Produtor criado")
        fetchProducers()
      } else {
        setError(result.error || "Erro ao salvar produtor")
      }
    } catch (err) {
      console.error("Error saving producer:", err)
      setError("Erro ao salvar produtor")
    }
  }

  async function handleDelete(id: string, e: React.MouseEvent) {
    e.preventDefault()
    e.stopPropagation()
    const ok = await confirmDialog({ title: "Excluir produtor", message: "Deseja realmente excluir este produtor?", destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/producers/${id}`, { method: "DELETE" })
      const result = await res.json()
      if (res.ok) {
        success("Produtor excluído")
        fetchProducers()
      } else {
        toastError(result.error || "Erro ao excluir produtor")
      }
    } catch (error) {
      console.error("Error deleting producer:", error)
      toastError("Erro ao excluir produtor")
    }
  }

  const filtered = producers.filter(p =>
    p.name.toLowerCase().includes(searchTerm.toLowerCase())
  )

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Produtores</h1>
          <p className="text-muted-foreground">Safra 2026 — fazendas, talhões e colheita por produtor.</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={fetchProducers} disabled={loading}>
            <RefreshCcw className={loading ? "mr-2 h-4 w-4 animate-spin" : "mr-2 h-4 w-4"} />
            Sincronizar
          </Button>
          <Button
            className="bg-primary shadow-lg shadow-primary/20"
            onClick={() => { setEditingProducer(null); setError(null); setIsModalOpen(true) }}
          >
            <UserPlus className="mr-2 h-4 w-4" />
            Novo Produtor
          </Button>
        </div>
      </div>

      <div className="relative flex-1 w-full">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Buscar por nome..."
          className="pl-10 h-11"
          value={searchTerm}
          onChange={e => setSearchTerm(e.target.value)}
        />
      </div>

      {loading ? (
        <div className="p-12 text-center">
          <Loader2 className="h-8 w-8 animate-spin mx-auto text-primary" />
        </div>
      ) : filtered.length === 0 ? (
        <Card>
          <CardContent className="p-12 text-center text-muted-foreground">
            Nenhum produtor encontrado.
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {filtered.map((p) => {
            const areaTotal = (p.farms || []).reduce(
              (acc: number, f: any) => acc + (f.plots || []).reduce((a: number, t: any) => a + t.areaHa, 0),
              0
            )
            const totalPlots = (p.farms || []).reduce((acc: number, f: any) => acc + (f.plots || []).length, 0)
            const bales = (p.harvestLots || []).reduce((acc: number, l: any) => acc + l.bales, 0)

            return (
              <Link key={p.id} href={`/producers/${p.id}`} className="group">
                <Card className="h-full transition-transform duration-200 group-hover:-translate-y-0.5">
                  <CardContent className="p-5 sm:p-6">
                    <div className="flex items-center justify-between gap-3 mb-4">
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold shrink-0">
                          {initials(p.name)}
                        </div>
                        <p className="font-semibold leading-none truncate">{p.name}</p>
                      </div>
                      <Badge variant={statusVariant(p.status)}>{p.status}</Badge>
                    </div>
                    <div className="grid grid-cols-3 gap-2 text-center text-sm pt-3 border-t border-zinc-800/50">
                      <div>
                        <p className="text-muted-foreground text-xs flex items-center justify-center gap-1"><MapPin className="h-3 w-3" />Área</p>
                        <p className="font-semibold mt-0.5">{areaTotal || "-"}{areaTotal ? " ha" : ""}</p>
                      </div>
                      <div>
                        <p className="text-muted-foreground text-xs">Talhões</p>
                        <p className="font-semibold mt-0.5">{totalPlots || "-"}</p>
                      </div>
                      <div>
                        <p className="text-muted-foreground text-xs flex items-center justify-center gap-1"><Package className="h-3 w-3" />Fardos</p>
                        <p className="font-semibold mt-0.5">{bales || "-"}</p>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </Link>
            )
          })}
        </div>
      )}

      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingProducer ? "Editar Produtor" : "Novo Produtor"}
      >
        {error && (
          <div className="mb-4 p-3 rounded-md bg-red-500/10 border border-red-500/20 text-sm text-red-500">
            {error}
          </div>
        )}
        <ProducerForm
          initialData={editingProducer}
          onCancel={() => setIsModalOpen(false)}
          onSubmit={handleCreateOrUpdate}
        />
      </Modal>
    </div>
  )
}
