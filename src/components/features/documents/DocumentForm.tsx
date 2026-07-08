"use client"

import * as React from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Loader2 } from "lucide-react"

interface DocumentFormProps {
  initialData?: any
  suppliers: any[]
  assets: any[]
  onSubmit: (data: any) => Promise<void>
  onCancel: () => void
}

export function DocumentForm({ initialData, suppliers, assets, onSubmit, onCancel }: DocumentFormProps) {
  const [loading, setLoading] = React.useState(false)
  const [formData, setFormData] = React.useState({
    type: initialData?.type || "CERTIFICADO",
    title: initialData?.title || "",
    holder: initialData?.holder || "",
    validUntil: initialData?.validUntil ? new Date(initialData.validUntil).toISOString().split('T')[0] : "",
    supplierId: initialData?.supplierId || "",
    assetId: initialData?.assetId || "",
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
          <label className="text-sm font-medium">Tipo</label>
          <select
            className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            value={formData.type}
            onChange={e => setFormData({ ...formData, type: e.target.value })}
          >
            <option value="CERTIFICADO">Certificado Digital</option>
            <option value="LICENCA">Licença de Software</option>
          </select>
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Validade</label>
          <Input
            type="date"
            required
            value={formData.validUntil}
            onChange={e => setFormData({ ...formData, validUntil: e.target.value })}
          />
        </div>
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium">Nome / Descrição</label>
        <Input
          required
          placeholder="Ex: Certificado A1 Cotton Nova Prata, Licença Windows Server..."
          value={formData.title}
          onChange={e => setFormData({ ...formData, title: e.target.value })}
        />
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium">Titular (CNPJ/CPF ou empresa)</label>
        <Input
          required
          placeholder="Ex: Cotton Nova Prata LTDA"
          value={formData.holder}
          onChange={e => setFormData({ ...formData, holder: e.target.value })}
        />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Fornecedor</label>
          <select
            className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            value={formData.supplierId}
            onChange={e => setFormData({ ...formData, supplierId: e.target.value })}
          >
            <option value="">Nenhum</option>
            {suppliers.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
          </select>
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Instalado em (ativo)</label>
          <select
            className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            value={formData.assetId}
            onChange={e => setFormData({ ...formData, assetId: e.target.value })}
          >
            <option value="">Nenhum</option>
            {assets.map(a => <option key={a.id} value={a.id}>{a.tag} - {a.name}</option>)}
          </select>
        </div>
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium">Observação</label>
        <textarea
          className="flex min-h-[60px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
          value={formData.notes}
          onChange={e => setFormData({ ...formData, notes: e.target.value })}
        />
      </div>

      <div className="flex justify-end gap-3 pt-4 border-t">
        <Button variant="outline" type="button" onClick={onCancel}>Cancelar</Button>
        <Button type="submit" disabled={loading}>
          {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : initialData ? "Atualizar" : "Cadastrar"}
        </Button>
      </div>
    </form>
  )
}
