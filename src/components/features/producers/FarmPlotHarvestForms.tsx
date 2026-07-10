"use client"

import * as React from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Loader2 } from "lucide-react"

export function FarmForm({ initialData, onSubmit, onCancel }: { initialData?: any; onSubmit: (d: any) => Promise<void>; onCancel: () => void }) {
  const [loading, setLoading] = React.useState(false)
  const [name, setName] = React.useState(initialData?.name || "")

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    try {
      await onSubmit({ name })
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="space-y-2">
        <label className="text-sm font-medium">Nome da fazenda</label>
        <Input required value={name} onChange={e => setName(e.target.value)} placeholder="Ex: Fazenda Boa Vista" />
      </div>
      <div className="flex justify-end gap-3 pt-2 border-t border-zinc-800/50">
        <Button type="button" variant="ghost" onClick={onCancel}>Cancelar</Button>
        <Button type="submit" disabled={loading}>
          {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
          Salvar
        </Button>
      </div>
    </form>
  )
}

export function PlotForm({ initialData, onSubmit, onCancel }: { initialData?: any; onSubmit: (d: any) => Promise<void>; onCancel: () => void }) {
  const [loading, setLoading] = React.useState(false)
  const [formData, setFormData] = React.useState({
    name: initialData?.name || "",
    areaHa: initialData?.areaHa || "",
    variety: initialData?.variety || "",
    splitArea: initialData?.splitArea || false,
    season: initialData?.season || "2026",
    notes: initialData?.notes || "",
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
          <label className="text-sm font-medium">Talhão</label>
          <Input required value={formData.name} onChange={e => setFormData({ ...formData, name: e.target.value })} placeholder="Ex: 01 e 02" />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Área (ha)</label>
          <Input required type="number" step="0.01" min="0.01" value={formData.areaHa} onChange={e => setFormData({ ...formData, areaHa: e.target.value })} />
        </div>
      </div>
      <div className="space-y-2">
        <label className="text-sm font-medium">Variedade</label>
        <Input required value={formData.variety} onChange={e => setFormData({ ...formData, variety: e.target.value })} placeholder="Ex: FB 911" />
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Safra</label>
          <Input value={formData.season} onChange={e => setFormData({ ...formData, season: e.target.value })} />
        </div>
        <div className="flex items-end pb-2">
          <label className="text-sm font-medium flex items-center gap-2">
            <input type="checkbox" checked={formData.splitArea} onChange={e => setFormData({ ...formData, splitArea: e.target.checked })} />
            Área dividida entre variedades
          </label>
        </div>
      </div>
      <div className="space-y-2">
        <label className="text-sm font-medium">Observações</label>
        <textarea
          className="flex w-full rounded-lg border border-zinc-700/50 bg-background px-3 py-2 text-sm min-h-[60px]"
          value={formData.notes}
          onChange={e => setFormData({ ...formData, notes: e.target.value })}
        />
      </div>
      <div className="flex justify-end gap-3 pt-2 border-t border-zinc-800/50">
        <Button type="button" variant="ghost" onClick={onCancel}>Cancelar</Button>
        <Button type="submit" disabled={loading}>
          {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
          Salvar
        </Button>
      </div>
    </form>
  )
}

export function HarvestLotForm({ initialData, onSubmit, onCancel }: { initialData?: any; onSubmit: (d: any) => Promise<void>; onCancel: () => void }) {
  const [loading, setLoading] = React.useState(false)
  const [formData, setFormData] = React.useState({
    blockNumber: initialData?.blockNumber || "",
    plot: initialData?.plot || "",
    harvestDate: initialData?.harvestDate ? String(initialData.harvestDate).slice(0, 10) : "",
    classification: initialData?.classification || "",
    bales: initialData?.bales || "",
    totalWeightKg: initialData?.totalWeightKg || "",
    status: initialData?.status || "colhido",
    invoiceNumber: initialData?.invoiceNumber || "",
    notes: initialData?.notes || "",
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
          <label className="text-sm font-medium">Nº do bloco</label>
          <Input value={formData.blockNumber} onChange={e => setFormData({ ...formData, blockNumber: e.target.value })} />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Talhão</label>
          <Input value={formData.plot} onChange={e => setFormData({ ...formData, plot: e.target.value })} />
        </div>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Data da colheita</label>
          <Input type="date" value={formData.harvestDate} onChange={e => setFormData({ ...formData, harvestDate: e.target.value })} />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Classificação</label>
          <Input value={formData.classification} onChange={e => setFormData({ ...formData, classification: e.target.value })} placeholder="Ex: 31.3" />
        </div>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Fardos</label>
          <Input required type="number" min="0" value={formData.bales} onChange={e => setFormData({ ...formData, bales: e.target.value })} />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Peso total (kg)</label>
          <Input required type="number" step="0.01" min="0" value={formData.totalWeightKg} onChange={e => setFormData({ ...formData, totalWeightKg: e.target.value })} />
        </div>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Status</label>
          <select
            className="flex h-9 w-full rounded-lg border border-zinc-700/50 bg-background px-3 py-2 text-sm"
            value={formData.status}
            onChange={e => setFormData({ ...formData, status: e.target.value })}
          >
            <option value="colhido">Colhido</option>
            <option value="beneficiado">Beneficiado</option>
            <option value="faturado">Faturado</option>
            <option value="cancelado">Cancelado</option>
          </select>
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Nota fiscal</label>
          <Input value={formData.invoiceNumber} onChange={e => setFormData({ ...formData, invoiceNumber: e.target.value })} />
        </div>
      </div>
      <div className="space-y-2">
        <label className="text-sm font-medium">Observações</label>
        <textarea
          className="flex w-full rounded-lg border border-zinc-700/50 bg-background px-3 py-2 text-sm min-h-[60px]"
          value={formData.notes}
          onChange={e => setFormData({ ...formData, notes: e.target.value })}
        />
      </div>
      <div className="flex justify-end gap-3 pt-2 border-t border-zinc-800/50">
        <Button type="button" variant="ghost" onClick={onCancel}>Cancelar</Button>
        <Button type="submit" disabled={loading}>
          {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
          Salvar
        </Button>
      </div>
    </form>
  )
}
