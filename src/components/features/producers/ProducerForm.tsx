"use client"

import * as React from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Loader2 } from "lucide-react"

interface ProducerFormProps {
  initialData?: any
  onSubmit: (data: any) => Promise<void>
  onCancel: () => void
}

export function ProducerForm({ initialData, onSubmit, onCancel }: ProducerFormProps) {
  const [loading, setLoading] = React.useState(false)
  const [formData, setFormData] = React.useState({
    name: initialData?.name || "",
    document: initialData?.document || "",
    stateRegistration: initialData?.stateRegistration || "",
    address: initialData?.address || "",
    phone: initialData?.phone || "",
    email: initialData?.email || "",
    whatsapp: initialData?.whatsapp || "",
    status: initialData?.status || "ativo",
    notes: initialData?.notes || "",
    contractNumber: initialData?.contractNumber || "",
    contractedAreaHa: initialData?.contractedAreaHa || "",
    expectedBales: initialData?.expectedBales || "",
    lotCount: initialData?.lotCount || "",
    blockSequence: initialData?.blockSequence || "",
    hviLab: initialData?.hviLab || "",
    visualLab: initialData?.visualLab || "",
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
          <label className="text-sm font-medium">Nome</label>
          <Input required value={formData.name} onChange={e => setFormData({ ...formData, name: e.target.value })} />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">CPF/CNPJ</label>
          <Input value={formData.document} onChange={e => setFormData({ ...formData, document: e.target.value })} />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Inscrição Estadual</label>
          <Input value={formData.stateRegistration} onChange={e => setFormData({ ...formData, stateRegistration: e.target.value })} />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Endereço</label>
          <Input value={formData.address} onChange={e => setFormData({ ...formData, address: e.target.value })} />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Telefone</label>
          <Input value={formData.phone} onChange={e => setFormData({ ...formData, phone: e.target.value })} />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">WhatsApp</label>
          <Input value={formData.whatsapp} onChange={e => setFormData({ ...formData, whatsapp: e.target.value })} />
        </div>
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium">E-mail</label>
        <Input type="email" value={formData.email} onChange={e => setFormData({ ...formData, email: e.target.value })} />
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium">Status</label>
        <select
          className="flex h-9 w-full rounded-lg border border-zinc-700/50 bg-background px-3 py-2 text-sm"
          value={formData.status}
          onChange={e => setFormData({ ...formData, status: e.target.value })}
        >
          <option value="ativo">Ativo</option>
          <option value="pendente">Pendente</option>
          <option value="inativo">Inativo</option>
        </select>
      </div>

      <div className="pt-2 border-t border-zinc-800/50">
        <p className="text-xs font-semibold uppercase tracking-wide text-zinc-500 mb-3">Contrato da safra</p>
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-2">
            <label className="text-sm font-medium">Nº do contrato</label>
            <Input value={formData.contractNumber} onChange={e => setFormData({ ...formData, contractNumber: e.target.value })} placeholder="Ex: 002/2026" />
          </div>
          <div className="space-y-2">
            <label className="text-sm font-medium">Área contratada (ha)</label>
            <Input type="number" step="0.01" min="0" value={formData.contractedAreaHa} onChange={e => setFormData({ ...formData, contractedAreaHa: e.target.value })} />
          </div>
        </div>
        <div className="grid grid-cols-2 gap-4 mt-4">
          <div className="space-y-2">
            <label className="text-sm font-medium">Fardinho (meta de fardos)</label>
            <Input type="number" min="0" value={formData.expectedBales} onChange={e => setFormData({ ...formData, expectedBales: e.target.value })} />
          </div>
          <div className="space-y-2">
            <label className="text-sm font-medium">Lotes</label>
            <Input type="number" min="0" value={formData.lotCount} onChange={e => setFormData({ ...formData, lotCount: e.target.value })} />
          </div>
        </div>
        <div className="space-y-2 mt-4">
          <label className="text-sm font-medium">Sequência de blocos</label>
          <Input value={formData.blockSequence} onChange={e => setFormData({ ...formData, blockSequence: e.target.value })} placeholder="Ex: 001 A 100" />
        </div>
        <div className="grid grid-cols-2 gap-4 mt-4">
          <div className="space-y-2">
            <label className="text-sm font-medium">Laboratório HVI</label>
            <Input value={formData.hviLab} onChange={e => setFormData({ ...formData, hviLab: e.target.value })} placeholder="Ex: COABRA" />
          </div>
          <div className="space-y-2">
            <label className="text-sm font-medium">Laboratório Visual</label>
            <Input value={formData.visualLab} onChange={e => setFormData({ ...formData, visualLab: e.target.value })} placeholder="Ex: DS COTTON" />
          </div>
        </div>
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium">Observações</label>
        <textarea
          className="flex w-full rounded-lg border border-zinc-700/50 bg-background px-3 py-2 text-sm min-h-[80px]"
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
