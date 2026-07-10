"use client"

import * as React from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Loader2 } from "lucide-react"

interface MaintenanceFormProps {
  initialData?: any
  assets: any[]
  onSubmit: (data: any) => Promise<void>
  onCancel: () => void
}

export function MaintenanceForm({ initialData, assets, onSubmit, onCancel }: MaintenanceFormProps) {
  const [loading, setLoading] = React.useState(false)
  const [formData, setFormData] = React.useState({
    assetId: initialData?.assetId || "",
    problem: initialData?.problem || "",
    description: initialData?.description || "",
    status: initialData?.status || "PENDENTE",
    technician: initialData?.technician || "",
    cost: initialData?.cost?.toString() || "",
    startDate: initialData?.startDate ? new Date(initialData.startDate).toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
    endDate: initialData?.endDate ? new Date(initialData.endDate).toISOString().split('T')[0] : ""
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
      <div className="space-y-2">
        <label className="text-sm font-medium">Ativo</label>
        <select 
          className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
          value={formData.assetId}
          onChange={e => setFormData({...formData, assetId: e.target.value})}
          required
          disabled={!!initialData} // Usually we don't change the asset after creation
        >
          <option value="">Selecione um ativo...</option>
          {assets.map(a => (
            <option key={a.id} value={a.id}>{a.tag} - {a.name}</option>
          ))}
        </select>
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium">Problema Relatado</label>
        <Input 
          required 
          placeholder="Ex: Teclado falhando, Tela azul..."
          value={formData.problem} 
          onChange={e => setFormData({...formData, problem: e.target.value})} 
        />
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium">Descrição Detalhada</label>
        <textarea 
          className="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
          placeholder="Descreva o problema e observações técnicas..."
          value={formData.description}
          onChange={e => setFormData({...formData, description: e.target.value})}
        />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Status</label>
          <select 
            className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            value={formData.status}
            onChange={e => setFormData({...formData, status: e.target.value})}
          >
            <option value="PENDENTE">Pendente</option>
            <option value="EM_PROGRESSO">Em Progresso</option>
            <option value="CONCLUIDO">Concluído</option>
            <option value="CANCELADO">Cancelado</option>
          </select>
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Técnico Responsável</label>
          <Input 
            required 
            placeholder="Nome do técnico"
            value={formData.technician} 
            onChange={e => setFormData({...formData, technician: e.target.value})} 
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Custo (R$)</label>
          <Input 
            type="number" 
            step="0.01" 
            min="0"
            placeholder="0,00"
            value={formData.cost} 
            onChange={e => setFormData({...formData, cost: e.target.value})} 
          />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Data de Início</label>
          <Input 
            type="date"
            required
            value={formData.startDate} 
            onChange={e => setFormData({...formData, startDate: e.target.value})} 
          />
        </div>
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium">Data de Conclusão (opcional)</label>
        <Input 
          type="date"
          value={formData.endDate} 
          onChange={e => setFormData({...formData, endDate: e.target.value})} 
        />
      </div>

      <div className="flex justify-end gap-3 pt-4 border-t">
        <Button variant="outline" type="button" onClick={onCancel}>Cancelar</Button>
        <Button type="submit" disabled={loading}>
          {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : initialData ? "Atualizar" : "Registrar"} Manutenção
        </Button>
      </div>
    </form>
  )
}
