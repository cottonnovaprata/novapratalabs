"use client"

import React from "react"
import { useParams, useRouter } from "next/navigation"
import { ArrowLeft, Loader2, Phone, Mail, MessageCircle, MapPin, Building2, LayoutGrid, Package } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { AnimatedCounter } from "@/components/ui/animated-counter"
import { AuroraGlow } from "@/components/aurora-glow"
import { cn } from "@/lib/utils"

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
  const [producer, setProducer] = React.useState<any>(null)
  const [loading, setLoading] = React.useState(true)
  const [tab, setTab] = React.useState<(typeof TABS)[number]>("Fazendas e talhões")

  React.useEffect(() => {
    async function fetchProducer() {
      setLoading(true)
      try {
        const res = await fetch(`/api/producers/${params.id}`)
        if (res.ok) setProducer(await res.json())
      } catch (error) {
        console.error("Error fetching producer:", error)
      } finally {
        setLoading(false)
      }
    }
    if (params.id) fetchProducer()
  }, [params.id])

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
    { label: "Área total", value: areaTotal, suffix: " ha", icon: MapPin, color: "text-emerald-500", bg: "bg-emerald-500/10" },
    { label: "Fazendas", value: producer.farms?.length || 0, icon: Building2, color: "text-blue-500", bg: "bg-blue-500/10" },
    { label: "Talhões", value: totalPlots, icon: LayoutGrid, color: "text-amber-500", bg: "bg-amber-500/10" },
    { label: "Fardos colhidos", value: bales, icon: Package, color: "text-violet-500", bg: "bg-violet-500/10" },
  ]

  return (
    <div className="relative space-y-6 animate-in fade-in duration-500 max-w-4xl">
      <AuroraGlow />

      <Button variant="ghost" size="sm" onClick={() => router.push("/producers")}>
        <ArrowLeft className="mr-2 h-4 w-4" />
        Voltar
      </Button>

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
                <AnimatedCounter value={s.value} />{s.suffix || ""}
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
          {(!producer.farms || producer.farms.length === 0) && (
            <Card><CardContent className="p-6 text-sm" style={{ color: "var(--text-tertiary)" }}>Nenhuma fazenda/talhão cadastrado ainda.</CardContent></Card>
          )}
          {(producer.farms || []).map((f: any) => (
            <Card key={f.id}>
              <CardContent className="p-5 sm:p-6">
                <p className="font-semibold text-sm mb-4 flex items-center gap-2" style={{ color: "var(--text-primary)" }}>
                  <MapPin className="h-4 w-4 text-emerald-500" />{f.name}
                </p>
                <table className="w-full text-sm">
                  <thead>
                    <tr style={{ borderBottom: "1px solid var(--border)" }}>
                      <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Talhão</th>
                      <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Área</th>
                      <th className="pb-2.5 text-left text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>Variedade</th>
                    </tr>
                  </thead>
                  <tbody>
                    {f.plots.map((t: any) => (
                      <tr key={t.id} className="transition-colors duration-200 hover:bg-zinc-500/5" style={{ borderBottom: "1px solid var(--border)" }}>
                        <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{t.name}</td>
                        <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{t.areaHa} ha</td>
                        <td className="py-2.5" style={{ color: "var(--text-primary)" }}>
                          {t.variety}
                          {t.splitArea && <span className="ml-2 text-xs" style={{ color: "var(--text-tertiary)" }}>(área dividida)</span>}
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
                  </tr>
                </thead>
                <tbody>
                  {producer.harvestLots.map((l: any) => (
                    <tr key={l.id} className="transition-colors duration-200 hover:bg-zinc-500/5" style={{ borderBottom: "1px solid var(--border)" }}>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{l.blockNumber || "-"}</td>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{l.plot || "-"}</td>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{l.bales}</td>
                      <td className="py-2.5" style={{ color: "var(--text-primary)" }}>{l.totalWeightKg}</td>
                      <td className="py-2.5"><Badge variant="ghost">{l.status}</Badge></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </CardContent>
        </Card>
      )}

      {tab === "Documentos" && (
        <Card><CardContent className="p-5 sm:p-6 text-sm" style={{ color: "var(--text-tertiary)" }}>Upload de documentos entra aqui (contratos, CAR, notas).</CardContent></Card>
      )}
    </div>
  )
}
