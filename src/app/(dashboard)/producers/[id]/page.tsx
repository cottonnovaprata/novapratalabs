"use client"

import React from "react"
import { useParams, useRouter } from "next/navigation"
import { ArrowLeft, Loader2, Phone, Mail, MessageCircle, MapPin } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"

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
      <div className="p-12 text-center">
        <Loader2 className="h-8 w-8 animate-spin mx-auto text-primary" />
      </div>
    )
  }

  if (!producer) {
    return (
      <div className="p-12 text-center text-muted-foreground">
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
    { label: "Área total", value: areaTotal ? `${areaTotal} ha` : "-" },
    { label: "Fazendas", value: producer.farms?.length || "-" },
    { label: "Talhões", value: totalPlots || "-" },
    { label: "Fardos colhidos", value: bales || "-" },
  ]

  return (
    <div className="space-y-6 animate-in fade-in duration-500 max-w-4xl">
      <Button variant="ghost" size="sm" onClick={() => router.push("/producers")}>
        <ArrowLeft className="mr-2 h-4 w-4" />
        Voltar
      </Button>

      <Card>
        <CardContent className="p-5 sm:p-6 flex items-center justify-between flex-wrap gap-4">
          <div className="flex items-center gap-3">
            <div className="h-14 w-14 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold text-lg">
              {initials(producer.name)}
            </div>
            <div>
              <p className="font-semibold text-lg leading-none">{producer.name}</p>
              <p className="text-sm text-muted-foreground mt-1">Safra atual: 2026</p>
            </div>
          </div>
          <Badge variant={statusVariant(producer.status)}>{producer.status}</Badge>
        </CardContent>
      </Card>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {stats.map((m) => (
          <Card key={m.label}>
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">{m.label}</p>
              <p className="text-xl font-bold mt-1">{m.value}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="flex gap-0.5 border-b overflow-x-auto">
        {TABS.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`px-3 py-2 text-sm whitespace-nowrap transition-colors duration-200 ${
              tab === t ? "font-semibold text-primary border-b-2 border-primary" : "text-muted-foreground hover:text-foreground"
            }`}
          >
            {t}
          </button>
        ))}
      </div>

      {tab === "Dados gerais" && (
        <Card>
          <CardContent className="p-5 sm:p-6 space-y-4 text-sm">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-muted-foreground">CPF/CNPJ</p>
                <p className="mt-0.5">{producer.document || "-"}</p>
              </div>
              <div>
                <p className="text-xs text-muted-foreground">Inscrição Estadual</p>
                <p className="mt-0.5">{producer.stateRegistration || "-"}</p>
              </div>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Endereço</p>
              <p className="mt-0.5">{producer.address || "-"}</p>
            </div>
            <div className="pt-2 border-t space-y-3">
              <p className="flex items-center gap-2"><Phone className="h-4 w-4 text-muted-foreground" />{producer.phone || "-"}</p>
              <p className="flex items-center gap-2"><Mail className="h-4 w-4 text-muted-foreground" />{producer.email || "-"}</p>
              <p className="flex items-center gap-2"><MessageCircle className="h-4 w-4 text-muted-foreground" />{producer.whatsapp || "-"}</p>
            </div>
            <p className="text-muted-foreground pt-2 border-t">{producer.notes || "Sem observações."}</p>
          </CardContent>
        </Card>
      )}

      {tab === "Fazendas e talhões" && (
        <div className="space-y-4">
          {(!producer.farms || producer.farms.length === 0) && (
            <Card><CardContent className="p-6 text-sm text-muted-foreground">Nenhuma fazenda/talhão cadastrado ainda.</CardContent></Card>
          )}
          {(producer.farms || []).map((f: any) => (
            <Card key={f.id}>
              <CardContent className="p-5 sm:p-6">
                <p className="font-semibold text-sm mb-3 flex items-center gap-2"><MapPin className="h-4 w-4 text-primary" />{f.name}</p>
                <table className="w-full text-sm">
                  <thead>
                    <tr className="text-left text-muted-foreground border-b">
                      <th className="pb-2 font-medium">Talhão</th>
                      <th className="pb-2 font-medium">Área</th>
                      <th className="pb-2 font-medium">Variedade</th>
                    </tr>
                  </thead>
                  <tbody>
                    {f.plots.map((t: any) => (
                      <tr key={t.id} className="border-b last:border-0 hover:bg-muted/50 transition-colors">
                        <td className="py-2">{t.name}</td>
                        <td className="py-2">{t.areaHa} ha</td>
                        <td className="py-2">
                          {t.variety}
                          {t.splitArea && <span className="ml-2 text-xs text-muted-foreground">(área dividida)</span>}
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
        <Card><CardContent className="p-5 sm:p-6 text-sm text-muted-foreground">Histórico multi-safra entra aqui quando tivermos mais de um ano cadastrado.</CardContent></Card>
      )}

      {tab === "Colheita e lotes" && (
        <Card>
          <CardContent className="p-5 sm:p-6">
            {(!producer.harvestLots || producer.harvestLots.length === 0) ? (
              <p className="text-sm text-muted-foreground">Nenhum lote lançado ainda.</p>
            ) : (
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-left text-muted-foreground border-b">
                    <th className="pb-2 font-medium">Bloco</th>
                    <th className="pb-2 font-medium">Talhão</th>
                    <th className="pb-2 font-medium">Fardos</th>
                    <th className="pb-2 font-medium">Peso (kg)</th>
                    <th className="pb-2 font-medium">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {producer.harvestLots.map((l: any) => (
                    <tr key={l.id} className="border-b last:border-0 hover:bg-muted/50 transition-colors">
                      <td className="py-2">{l.blockNumber || "-"}</td>
                      <td className="py-2">{l.plot || "-"}</td>
                      <td className="py-2">{l.bales}</td>
                      <td className="py-2">{l.totalWeightKg}</td>
                      <td className="py-2"><Badge variant="ghost">{l.status}</Badge></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </CardContent>
        </Card>
      )}

      {tab === "Documentos" && (
        <Card><CardContent className="p-5 sm:p-6 text-sm text-muted-foreground">Upload de documentos entra aqui (contratos, CAR, notas).</CardContent></Card>
      )}
    </div>
  )
}
