"use client"

import React from "react"
import { useParams, useRouter } from "next/navigation"
import {
  ArrowLeft, Loader2, Phone, Mail, MessageCircle, MapPin, Building2, LayoutGrid, Package,
  Edit, Trash2, Plus, Upload, Download, FileText,
} from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { AnimatedCounter } from "@/components/ui/animated-counter"
import { AuroraGlow } from "@/components/aurora-glow"
import { cn } from "@/lib/utils"
import { useConfirm } from "@/components/confirm-dialog-provider"
import { useToast } from "@/components/toast-provider"
import { ProducerForm } from "@/components/features/producers/ProducerForm"
import { FarmForm, PlotForm, HarvestLotForm } from "@/components/features/producers/FarmPlotHarvestForms"

const TABS = ["Dados gerais", "Fazendas e talhões", "Safras", "Colheita e lotes", "Documentos"] as const

function initials(name: string) {
  return name.split(" ").filter(Boolean).slice(0, 2).map(p => p[0]).join("").toUpperCase()
}

function statusVariant(status: string) {
  if (status === "ativo") return "success"
  if (status === "pendente") return "warning"
  return "outline"
}

export default function ProducerDetailPage() {
  const params = useParams<{ id: string }>()
  const router = useRouter()
  const confirmDialog = useConfirm()
  const { success, error: toastError } = useToast()

  const [producer, setProducer] = React.useState<any>(null)
  const [loading, setLoading] = React.useState(true)
  const [tab, setTab] = React.useState<(typeof TABS)[number]>("Fazendas e talhões")

  const [editProducerOpen, setEditProducerOpen] = React.useState(false)
  const [farmModal, setFarmModal] = React.useState<{ open: boolean; editing: any | null }>({ open: false, editing: null })
  const [plotModal, setPlotModal] = React.useState<{ open: boolean; editing: any | null; farmId: string | null }>({ open: false, editing: null, farmId: null })
  const [lotModal, setLotModal] = React.useState<{ open: boolean; editing: any | null }>({ open: false, editing: null })
  const [uploadingDoc, setUploadingDoc] = React.useState(false)

  const fetchProducer = React.useCallback(async () => {
    try {
      const res = await fetch(`/api/producers/${params.id}`)
      if (res.ok) setProducer(await res.json())
    } catch (error) {
      console.error("Error fetching producer:", error)
    } finally {
      setLoading(false)
    }
  }, [params.id])

  React.useEffect(() => { if (params.id) fetchProducer() }, [params.id, fetchProducer])

  async function handleEditProducer(data: any) {
    try {
      const res = await fetch(`/api/producers/${params.id}`, {
        method: "PUT",
        body: JSON.stringify(data),
        headers: { "Content-Type": "application/json" },
      })
      if (res.ok) {
        setEditProducerOpen(false)
        success("Produtor atualizado")
        fetchProducer()
      } else {
        toastError("Erro ao atualizar produtor")
      }
    } catch (error) {
      console.error(error)
      toastError("Erro ao atualizar produtor")
    }
  }

  async function handleDeleteProducer() {
    const ok = await confirmDialog({ title: "Excluir produtor", message: `Deseja realmente excluir ${producer.name}? Isso apaga fazendas, talhões e lotes vinculados.`, destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/producers/${params.id}`, { method: "DELETE" })
      if (res.ok) {
        success("Produtor excluído")
        router.push("/producers")
      } else {
        toastError("Erro ao excluir produtor")
      }
    } catch (error) {
      console.error(error)
      toastError("Erro ao excluir produtor")
    }
  }

  async function handleFarmSubmit(data: any) {
    try {
      const url = farmModal.editing ? `/api/farms/${farmModal.editing.id}` : `/api/producers/${params.id}/farms`
      const method = farmModal.editing ? "PUT" : "POST"
      const res = await fetch(url, { method, body: JSON.stringify(data), headers: { "Content-Type": "application/json" } })
      if (res.ok) {
        success(farmModal.editing ? "Fazenda atualizada" : "Fazenda criada")
        setFarmModal({ open: false, editing: null })
        fetchProducer()
      } else {
        toastError("Erro ao salvar fazenda")
      }
    } catch (error) {
      console.error(error)
      toastError("Erro ao salvar fazenda")
    }
  }

  async function handleDeleteFarm(farm: any) {
    const ok = await confirmDialog({ title: "Excluir fazenda", message: `Excluir "${farm.name}" e todos os talhões dela?`, destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/farms/${farm.id}`, { method: "DELETE" })
      if (res.ok) { success("Fazenda excluída"); fetchProducer() } else { toastError("Erro ao excluir fazenda") }
    } catch (error) {
      console.error(error)
      toastError("Erro ao excluir fazenda")
    }
  }

  async function handlePlotSubmit(data: any) {
    try {
      const url = plotModal.editing ? `/api/plots/${plotModal.editing.id}` : `/api/farms/${plotModal.farmId}/plots`
      const method = plotModal.editing ? "PUT" : "POST"
      const res = await fetch(url, { method, body: JSON.stringify(data), headers: { "Content-Type": "application/json" } })
      if (res.ok) {
        success(plotModal.editing ? "Talhão atualizado" : "Talhão criado")
        setPlotModal({ open: false, editing: null, farmId: null })
        fetchProducer()
      } else {
        toastError("Erro ao salvar talhão")
      }
    } catch (error) {
      console.error(error)
      toastError("Erro ao salvar talhão")
    }
  }

  async function handleDeletePlot(plot: any) {
    const ok = await confirmDialog({ title: "Excluir talhão", message: `Excluir o talhão "${plot.name}"?`, destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/plots/${plot.id}`, { method: "DELETE" })
      if (res.ok) { success("Talhão excluído"); fetchProducer() } else { toastError("Erro ao excluir talhão") }
    } catch (error) {
      console.error(error)
      toastError("Erro ao excluir talhão")
    }
  }

  async function handleLotSubmit(data: any) {
    try {
      const url = lotModal.editing ? `/api/harvest-lots/${lotModal.editing.id}` : `/api/producers/${params.id}/harvest-lots`
      const method = lotModal.editing ? "PUT" : "POST"
      const res = await fetch(url, { method, body: JSON.stringify(data), headers: { "Content-Type": "application/json" } })
      if (res.ok) {
        success(lotModal.editing ? "Lote atualizado" : "Lote lançado")
        setLotModal({ open: false, editing: null })
        fetchProducer()
      } else {
        toastError("Erro ao salvar lote")
      }
    } catch (error) {
      console.error(error)
      toastError("Erro ao salvar lote")
    }
  }

  async function handleDeleteLot(lot: any) {
    const ok = await confirmDialog({ title: "Excluir lote", message: `Excluir o lote "${lot.blockNumber || lot.id}"?`, destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/harvest-lots/${lot.id}`, { method: "DELETE" })
      if (res.ok) { success("Lote excluído"); fetchProducer() } else { toastError("Erro ao excluir lote") }
    } catch (error) {
      console.error(error)
      toastError("Erro ao excluir lote")
    }
  }

  async function handleFileUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    e.target.value = ""

    if (file.size > 4 * 1024 * 1024) {
      toastError("Arquivo maior que 4MB não é suportado")
      return
    }

    setUploadingDoc(true)
    try {
      const fileData = await new Promise<string>((resolve, reject) => {
        const reader = new FileReader()
        reader.onload = () => resolve(String(reader.result).split(",")[1])
        reader.onerror = reject
        reader.readAsDataURL(file)
      })

      const res = await fetch(`/api/producers/${params.id}/documents`, {
        method: "POST",
        body: JSON.stringify({ fileName: file.name, mimeType: file.type || "application/octet-stream", fileData }),
        headers: { "Content-Type": "application/json" },
      })

      if (res.ok) {
        success("Documento enviado")
        fetchProducer()
      } else {
        const result = await res.json().catch(() => null)
        toastError(result?.error || "Erro ao enviar documento")
      }
    } catch (error) {
      console.error(error)
      toastError("Erro ao enviar documento")
    } finally {
      setUploadingDoc(false)
    }
  }

  async function handleDeleteDocument(doc: any) {
    const ok = await confirmDialog({ title: "Excluir documento", message: `Excluir "${doc.fileName}"?`, destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/producer-documents/${doc.id}`, { method: "DELETE" })
      if (res.ok) { success("Documento excluído"); fetchProducer() } else { toastError("Erro ao excluir documento") }
    } catch (error) {
      console.error(error)
      toastError("Erro ao excluir documento")
    }
  }

  if (loading) {
    return (
      <div className="flex h-[80vh] items-center justify-center">
        <Loader2 className="h-10 w-10 animate-spin text-primary" />
      </div>
    )
  }

  if (!producer) {
    return (
      <div className="p-12 text-center" style={{ color: "var(--text-tertiary)" }}>
        Produtor não encontrado.
      </div>
    )
  }

  const areaTotal = (producer.farms || []).reduce(
    (acc: number, f: any) => acc + (f.plots || []).reduce((a: number, t: any) => a + t.areaHa, 0),
    0
  )
  const totalPlots = (producer.farms || []).reduce((acc: number, f: any) => acc + (f.plots || []).length, 0)
  const bales = (producer.harvestLots || []).reduce((acc: number, l: any) => acc + l.bales, 0)

  const stats = [
    { label: "Área total", value: areaTotal, decimals: 1, suffix: " ha", icon: MapPin, color: "text-emerald-500", bg: "bg-emerald-500/10" },
    { label: "Fazendas", value: producer.farms?.length || 0, decimals: 0, icon: Building2, color: "text-blue-500", bg: "bg-blue-500/10" },
    { label: "Talhões", value: totalPlots, decimals: 0, icon: LayoutGrid, color: "text-amber-500", bg: "bg-amber-500/10" },
    { label: "Fardos colhidos", value: bales, decimals: 0, icon: Package, color: "text-violet-500", bg: "bg-violet-500/10" },
  ]

  return (
    <div className="relative space-y-6 animate-in fade-in duration-500 max-w-4xl">
      <AuroraGlow />

      <div className="flex items-center justify-between">
        <Button variant="ghost" size="sm" onClick={() => router.push("/producers")}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Voltar
        </Button>
        <div className="flex gap-2">
          <Button onClick={() => setEditProducerOpen(true)} size="sm">
            <Edit className="mr-2 h-4 w-4" />
            Editar
          </Button>
          <Button onClick={handleDeleteProducer} variant="outline" size="sm" style={{ color: "var(--status-error)" }}>
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      </div>

      <Card>
        <CardContent className="p-5 sm:p-6 flex items-center justify-between flex-wrap gap-4">
          <div className="flex items-center gap-4">
            <div className="h-16 w-16 rounded-2xl bg-primary/10 flex items-center justify-center text-primary font-bold text-xl">
              {initials(producer.name)}
            </div>
            <div>
              <p className="font-bold text-xl leading-tight" style={{ color: "var(--text-primary)" }}>{producer.name}</p>
              <p className="text-sm mt-1" style={{ color: "var(--text-tertiary)" }}>Safra atual: 2026</p>
            </div>
          </div>
          <Badge variant={statusVariant(producer.status)}>{producer.status}</Badge>
        </CardContent>
      </Card>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {stats.map((s) => (
          <Card key={s.label}>
            <CardContent className="p-4 sm:p-5">
              <div className={cn("h-9 w-9 rounded-lg flex items-center justify-center mb-3", s.bg)}>
                <s.icon className={cn("h-4 w-4", s.color)} />
              </div>
              <p className="text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>{s.label}</p>
              <div className="text-2xl font-bold mt-1" style={{ letterSpacing: "-0.02em", color: "var(--text-primary)" }}>
                <AnimatedCounter value={s.value} decimals={s.decimals ?? 0} />{s.suffix || ""}
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="flex gap-1 overflow-x-auto" style={{ borderBottom: "1px solid var(--border)" }}>
        {TABS.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className="px-3 py-2.5 text-sm whitespace-nowrap transition-colors duration-200 font-medium"
            style={
              tab === t
                ? { color: "var(--primary)", borderBottom: "2px solid var(--primary)" }
                : { color: "var(--text-tertiary)" }
            }
          >
            {t}
          </button>
        ))}
      </div>

      {tab === "Dados gerais" && (
        <Card>
          <CardContent className="p-5 sm:p-6 space-y-5 text-sm">
            <div className="grid grid-cols-2 gap-5">
              <div>
                <p className="text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>CPF/CNPJ</p>
                <p className="mt-1" style={{ color: "var(--text-primary)" }}>{producer.document || "-"}</p>
              </div>
              <div>
                <p className="text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Inscrição Estadual</p>
                <p className="mt-1" style={{ color: "var(--text-primary)" }}>{producer.stateRegistration || "-"}</p>
              </div>
            </div>
            <div>
              <p className="text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Endereço</p>
              <p className="mt-1" style={{ color: "var(--text-primary)" }}>{producer.address || "-"}</p>
            </div>
            <div className="pt-4 space-y-3" style={{ borderTop: "1px solid var(--border)" }}>
              <p className="flex items-center gap-2"><Phone className="h-4 w-4" style={{ color: "var(--text-tertiary)" }} />{producer.phone || "-"}</p>
              <p className="flex items-center gap-2"><Mail className="h-4 w-4" style={{ color: "var(--text-tertiary)" }} />{producer.email || "-"}</p>
              <p className="flex items-center gap-2"><MessageCircle className="h-4 w-4" style={{ color: "var(--text-tertiary)" }} />{producer.whatsapp || "-"}</p>
            </div>
            <p className="pt-4" style={{ borderTop: "1px solid var(--border)", color: "var(--text-tertiary)" }}>
              {producer.notes || "Sem observações."}
            </p>
          </CardContent>
        </Card>
      )}

      {tab === "Fazendas e talhões" && (
        <div className="space-y-4">
          <div className="flex justify-end">
            <Button size="sm" onClick={() => setFarmModal({ open: true, editing: null })}>
              <Plus className="mr-2 h-4 w-4" />
              Nova fazenda
            </Button>
          </div>

          {(!producer.farms || producer.farms.length === 0) && (
            <Card><CardContent className="p-6 text-sm" style={{ color: "var(--text-tertiary)" }}>Nenhuma fazenda cadastrada ainda.</CardContent></Card>
          )}

          {(producer.farms || []).map((f: any) => (
            <Card key={f.id}>
              <CardContent className="p-5 sm:p-6">
                <div className="flex items-center justify-between mb-4">
                  <p className="font-semibold text-sm flex items-center gap-2" style={{ color: "var(--text-primary)" }}>
                    <MapPin className="h-4 w-4 text-emerald-500" />{f.name}
                  </p>
                  <div className="flex gap-1">
                    <Button size="sm" variant="ghost" onClick={() => setPlotModal({ open: true, editing: null, farmId: f.id })}>
                      <Plus className="mr-1 h-3.5 w-3.5" />
                      Talhão
                    </Button>
                    <Button size="icon" variant="ghost" className="h-8 w-8" onClick={() => setFarmModal({ open: true, editing: f })}>
                      <Edit className="h-3.5 w-3.5" />
                    </Button>
                    <Button size="icon" variant="ghost" className="h-8 w-8" style={{ color: "var(--status-error)" }} onClick={() => handleDeleteFarm(f)}>
                      <Trash2 className="h-3.5 w-3.5" />
                    </Button>
                  </div>
                </div>
                <table className="w-full text-sm">
                  <thead>
                    <tr style={{ borderBottom: "1px solid var(--border)" }}>
                      <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Talhão</th>
                      <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Área</th>
                      <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Variedade</th>
                      <th className="pb-2.5 text-right text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}></th>
                    </tr>
                  </thead>
                  <tbody>
                    {f.plots.map((t: any) => (
                      <tr key={t.id} className="group transition-colors duration-200 hover:bg-zinc-500/5" style={{ borderBottom: "1px solid var(--border)" }}>
                        <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{t.name}</td>
                        <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{t.areaHa} ha</td>
                        <td className="py-2.5" style={{ color: "var(--text-primary)" }}>
                          {t.variety}
                          {t.splitArea && <span className="ml-2 text-xs" style={{ color: "var(--text-tertiary)" }}>(área dividida)</span>}
                        </td>
                        <td className="py-2.5 text-right">
                          <div className="flex justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                            <Button size="icon" variant="ghost" className="h-7 w-7" onClick={() => setPlotModal({ open: true, editing: t, farmId: f.id })}>
                              <Edit className="h-3.5 w-3.5" />
                            </Button>
                            <Button size="icon" variant="ghost" className="h-7 w-7" style={{ color: "var(--status-error)" }} onClick={() => handleDeletePlot(t)}>
                              <Trash2 className="h-3.5 w-3.5" />
                            </Button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {tab === "Safras" && (
        <Card><CardContent className="p-5 sm:p-6 text-sm" style={{ color: "var(--text-tertiary)" }}>Histórico multi-safra entra aqui quando tivermos mais de um ano cadastrado.</CardContent></Card>
      )}

      {tab === "Colheita e lotes" && (
        <Card>
          <CardContent className="p-5 sm:p-6">
            <div className="flex justify-end mb-4">
              <Button size="sm" onClick={() => setLotModal({ open: true, editing: null })}>
                <Plus className="mr-2 h-4 w-4" />
                Novo lote
              </Button>
            </div>
            {(!producer.harvestLots || producer.harvestLots.length === 0) ? (
              <p className="text-sm" style={{ color: "var(--text-tertiary)" }}>Nenhum lote lançado ainda.</p>
            ) : (
              <table className="w-full text-sm">
                <thead>
                  <tr style={{ borderBottom: "1px solid var(--border)" }}>
                    <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Bloco</th>
                    <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Talhão</th>
                    <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Fardos</th>
                    <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Peso (kg)</th>
                    <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Status</th>
                    <th className="pb-2.5 text-right text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}></th>
                  </tr>
                </thead>
                <tbody>
                  {producer.harvestLots.map((l: any) => (
                    <tr key={l.id} className="group transition-colors duration-200 hover:bg-zinc-500/5" style={{ borderBottom: "1px solid var(--border)" }}>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{l.blockNumber || "-"}</td>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{l.plot || "-"}</td>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{l.bales}</td>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{l.totalWeightKg}</td>
                      <td className="py-2.5"><Badge variant="ghost">{l.status}</Badge></td>
                      <td className="py-2.5 text-right">
                        <div className="flex justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                          <Button size="icon" variant="ghost" className="h-7 w-7" onClick={() => setLotModal({ open: true, editing: l })}>
                            <Edit className="h-3.5 w-3.5" />
                          </Button>
                          <Button size="icon" variant="ghost" className="h-7 w-7" style={{ color: "var(--status-error)" }} onClick={() => handleDeleteLot(l)}>
                            <Trash2 className="h-3.5 w-3.5" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </CardContent>
        </Card>
      )}

      {tab === "Documentos" && (
        <Card>
          <CardContent className="p-5 sm:p-6 space-y-4">
            <div className="flex items-center justify-between">
              <p className="text-sm" style={{ color: "var(--text-tertiary)" }}>
                Contratos, CAR, procurações e outros anexos. Máximo 4MB por arquivo.
              </p>
              <label>
                <input
                  type="file"
                  className="hidden"
                  onChange={handleFileUpload}
                  disabled={uploadingDoc}
                />
                <Button size="sm" asChild disabled={uploadingDoc}>
                  <span>
                    {uploadingDoc ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Upload className="mr-2 h-4 w-4" />}
                    Enviar arquivo
                  </span>
                </Button>
              </label>
            </div>

            {(!producer.documents || producer.documents.length === 0) ? (
              <p className="text-sm" style={{ color: "var(--text-tertiary)" }}>Nenhum documento enviado ainda.</p>
            ) : (
              <table className="w-full text-sm">
                <thead>
                  <tr style={{ borderBottom: "1px solid var(--border)" }}>
                    <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Arquivo</th>
                    <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Tamanho</th>
                    <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Enviado em</th>
                    <th className="pb-2.5 text-right text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}></th>
                  </tr>
                </thead>
                <tbody>
                  {producer.documents.map((d: any) => (
                    <tr key={d.id} className="group transition-colors duration-200 hover:bg-zinc-500/5" style={{ borderBottom: "1px solid var(--border)" }}>
                      <td className="py-2.5 flex items-center gap-2" style={{ color: "var(--text-primary)" }}>
                        <FileText className="h-4 w-4" style={{ color: "var(--text-tertiary)" }} />
                        {d.fileName}
                      </td>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{(d.fileSize / 1024).toFixed(0)} KB</td>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{new Date(d.uploadedAt).toLocaleDateString("pt-BR")}</td>
                      <td className="py-2.5 text-right">
                        <div className="flex justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                          <Button size="icon" variant="ghost" className="h-7 w-7" onClick={() => window.open(`/api/producer-documents/${d.id}`, "_blank")} aria-label={`Baixar ${d.fileName}`}>
                            <Download className="h-3.5 w-3.5" />
                          </Button>
                          <Button size="icon" variant="ghost" className="h-7 w-7" style={{ color: "var(--status-error)" }} onClick={() => handleDeleteDocument(d)} aria-label={`Excluir ${d.fileName}`}>
                            <Trash2 className="h-3.5 w-3.5" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </CardContent>
        </Card>
      )}

      <Modal isOpen={editProducerOpen} onClose={() => setEditProducerOpen(false)} title="Editar Produtor">
        <ProducerForm initialData={producer} onCancel={() => setEditProducerOpen(false)} onSubmit={handleEditProducer} />
      </Modal>

      <Modal isOpen={farmModal.open} onClose={() => setFarmModal({ open: false, editing: null })} title={farmModal.editing ? "Editar Fazenda" : "Nova Fazenda"}>
        <FarmForm initialData={farmModal.editing} onCancel={() => setFarmModal({ open: false, editing: null })} onSubmit={handleFarmSubmit} />
      </Modal>

      <Modal isOpen={plotModal.open} onClose={() => setPlotModal({ open: false, editing: null, farmId: null })} title={plotModal.editing ? "Editar Talhão" : "Novo Talhão"}>
        <PlotForm initialData={plotModal.editing} onCancel={() => setPlotModal({ open: false, editing: null, farmId: null })} onSubmit={handlePlotSubmit} />
      </Modal>

      <Modal isOpen={lotModal.open} onClose={() => setLotModal({ open: false, editing: null })} title={lotModal.editing ? "Editar Lote" : "Novo Lote de Colheita"}>
        <HarvestLotForm initialData={lotModal.editing} onCancel={() => setLotModal({ open: false, editing: null })} onSubmit={handleLotSubmit} />
      </Modal>
    </div>
  )
          }
