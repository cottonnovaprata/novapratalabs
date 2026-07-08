"use client"

import * as React from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Loader2 } from "lucide-react"

interface SupplierFormProps {
  initialData?: any
  onSubmit: (data: any) => Promise<void>
  onCancel: () => void
}

export function SupplierForm({ initialData, onSubmit, onCancel }: SupplierFormProps) {
  const [loading, setLoading] = React.useState(false)
  const [formData, setFormData] = React.useState({
    name: initialData?.name || "",
    serviceType: initialData?.serviceType || "",
    contactName: initialData?.contactName || "",
    phone: initialData?.phone || "",
    email: initialData?.email || "",
    hasContract: initialData?.hasContract || false,
    contractEnd: initialData?.contractEnd ? new Date(initialData.contractEnd).toISOString().split('T')[0] : "",
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
          <label className="text-sm font-medium">Nome</label>
          <Input required value={formData.name} onChange={e => setFormData({ ...formData, name: e.target.value })} />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Tipo de Serviço</label>
          <Input
            required
            placeholder="Ex: Internet, Impressora, Balança, Certificado..."
            value={formData.serviceType}
            onChange={e => setFormData({ ...formData, serviceType: e.target.value })}
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Contato</label>
          <Input value={formData.contactName} onChange={e => setFormData({ ...formData, contactName: e.target.value })} />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Telefone</label>
          <Input value={formData.phone} onChange={e => setFormData({ ...formData, phone: e.target.value })} />
        </div>
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium">E-mail</label>
        <Input type="email" value={formData.email} onChange={e => setFormData({ ...formData, email: e.target.value })} />
      </div>

      <div className="grid grid-cols-2 gap-4 items-end">
        <label className="flex items-center gap-2 text-sm font-medium pb-2">
          <input
            type="checkbox"
            checked={formData.hasContract}
            onChange={e => setFormData({ ...formData, hasContract: e.target.checked })}
          />
          Tem contrato ativo
        </label>
        <div className="space-y-2">
          <label className="text-sm font-medium">Vencimento do Contrato</label>
          <Input
            type="date"
            disabled={!formData.hasContract}
            value={formData.contractEnd}
            onChange={e => setFormData({ ...formData, contractEnd: e.target.value })}
          />
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
