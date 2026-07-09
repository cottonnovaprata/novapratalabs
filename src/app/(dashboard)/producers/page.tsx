"use client"

import React from "react"
import Link from "next/link"
import { Search, UserPlus, Loader2, RefreshCcw, MapPin, LayoutGrid, Package, ArrowUpRight } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { AnimatedCounter } from "@/components/ui/animated-counter"
import { AuroraGlow } from "@/components/aurora-glow"
import { cn } from "@/lib/utils"
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

  const totalArea = producers.reduce(
    (acc, p) => acc + (p.farms || []).reduce((a: number, f: any) => a + (f.plots || []).reduce((x: number, t: any) => x + t.areaHa, 0), 0),
    0
  )
  const totalBales = producers.reduce((acc, p) => acc + (p.harvestLots || []).reduce((a: number, l: any) => a + l.bales, 0), 0)

  if (loading) {
    return (
      <div className="flex h-[80vh] items-center justify-center">
        <Loader2 className="h-10 w-10 animate-spin text-primary" />
      </div>
    )
  }

  return (
    <div className="relative space-y-8 animate-in fade-in duration-500">
      <AuroraGlow />

      <div className="flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
        <div className="flex-1">
          <h1 className="text-3xl sm:text-4xl font-bold tracking-tight" style={{ color: "var(--text-primary)" }}>
            Produtores
          </h1>
          <p className="text-sm mt-2" style={{ color: "var(--text-tertiary)" }}>
            Safra 2026 — fazendas, talhões e colheita por produtor
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={fetchProducers} disabled={loading}>
            <RefreshCcw className={cn("mr-2 h-4 w-4", loading && "animate-spin")} />
            Sincronizar
          </Button>
          <Button
            size="sm"
            className="bg-primary shadow-lg shadow-primary/20"
            onClick={() => { setEditingProducer(null); setError(null); setIsModalOpen(true) }}
          >
            <UserPlus className="mr-2 h-4 w-4" />
            Novo Produtor
          </Button>
        </div>
      </div>

      <div className="grid gap-6 sm:grid-cols-3">
        {[
          { label: "Produtores", value: producers.length, icon: UserPlus, color: "text-blue-500", bg: "bg-blue-500/10" },
          { label: "Área plantada", value: totalArea, suffix: " ha", icon: MapPin, color: "text-emerald-500", bg: "bg-emerald-500/10" },
          { label: "Fardos colhidos", value: totalBales, icon: Package, color: "text-violet-500", bg: "bg-violet-500/10" },
        ].map((s) => (
          <Card key={s.label}>
            <CardContent className="p-5 sm:p-6 flex items-center justify-between">
              <div>
                <p className="text-xs sm:text-sm font-semibold" style={{ color: "var(--text-tertiary)" }}>{s.label}</p>
                <div className="text-3xl font-bold mt-2" style={{ letterSpacing: "-0.03em", color: "var(--text-primary)" }}>
                  <AnimatedCounter value={s.value} />{s.suffix || ""}
                </div>
              </div>
              <div className={cn("p-3 rounded-xl flex-shrink-0", s.bg)}>
                <s.icon className={cn("h-5 w-5", s.color)} />
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="relative flex-1 w-full">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4" style={{ color: "var(--text-tertiary)" }} />
        <Input
          placeholder="Buscar por nome..."
          className="pl-10 h-11"
          value={searchTerm}
          onChange={e => setSearchTerm(e.target.value)}
        />
      </div>

      {filtered.length === 0 ? (
        <Card>
          <CardContent className="p-12 text-center" style={{ color: "var(--text-tertiary)" }}>
            Nenhum produtor encontrado.
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {filtered.map((p) => {
            const areaTotal = (p.farms || []).reduce(
              (acc: number, f: any) => acc + (f.plots || []).reduce((a: number, t: any) => a + t.areaHa, 0),
              0
            )
            const totalPlots = (p.farms || []).reduce((acc: number, f: any) => acc + (f.plots || []).length, 0)
            const bales = (p.harvestLots || []).reduce((acc: number, l: any) => acc + l.bales, 0)

            return (
              <Link key={p.id} href={`/producers/${p.id}`} className="group block">
                <Card className="cursor-pointer hover:border-blue-200 hover:shadow-lg transition-all duration-200">
                  <CardContent className="p-5 sm:p-6">
                    <div className="flex items-center justify-between gap-3 mb-5">
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="h-11 w-11 rounded-xl bg-primary/10 flex items-center justify-center text-primary font-bold shrink-0">
                          {initials(p.name)}
                        </div>
                        <p className="font-semibold leading-tight truncate" style={{ color: "var(--text-primary)" }}>{p.name}</p>
                      </div>
                      <ArrowUpRight className="h-4 w-4 text-primary opacity-0 transition-opacity group-hover:opacity-100 flex-shrink-0" />
                    </div>

                    <div className="flex items-center justify-between mb-4">
                      <Badge variant={statusVariant(p.status)}>{p.status}</Badge>
                    </div>

                    <div className="grid grid-cols-3 gap-2 text-center pt-4" style={{ borderTop: "1px solid var(--border)" }}>
                      <div>
                        <p className="text-xs flex items-center justify-center gap-1" style={{ color: "var(--text-tertiary)" }}><MapPin className="h-3 w-3" />Área</p>
                        <p className="font-semibold mt-1" style={{ color: "var(--text-primary)" }}>{areaTotal || "-"}{areaTotal ? " ha" : ""}</p>
                      </div>
                      <div>
                        <p className="text-xs flex items-center justify-center gap-1" style={{ color: "var(--text-tertiary)" }}><LayoutGrid className="h-3 w-3" />Talhões</p>
                        <p className="font-semibold mt-1" style={{ color: "var(--text-primary)" }}>{totalPlots || "-"}</p>
                      </div>
                      <div>
                        <p className="text-xs flex items-center justify-center gap-1" style={{ color: "var(--text-tertiary)" }}><Package className="h-3 w-3" />Fardos</p>
                        <p className="font-semibold mt-1" style={{ color: "var(--text-primary)" }}>{bales || "-"}</p>
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
