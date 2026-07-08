"use client"

import * as React from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Loader2 } from "lucide-react"

const CATEGORIES = [
  "Internet", "Impressora", "Sistema", "Nota Fiscal", "Certificado",
  "Computador Lento", "Balança", "Câmera", "E-mail", "Acesso",
  "Servidor", "Rede", "Backup", "Segurança", "Outro",
]

interface TicketFormProps {
  initialData?: any
  assets: any[]
  onSubmit: (data: any) => Promise<void>
  onCancel: () => void
}

export function TicketForm({ initialData, assets, onSubmit, onCancel }: TicketFormProps) {
  const [loading, setLoading] = React.useState(false)
  const [formData, setFormData] = React.useState({
    requesterName: initialData?.requesterName || "",
    sector: initialData?.sector || "",
    category: initialData?.category || CATEGORIES[0],
    description: initialData?.description || "",
    priority: initialData?.priority || "MEDIA",
    status: initialData?.status || "ABERTO",
    assetId: initialData?.assetId || "",
    solution: initialData?.solution || "",
    recurring: initialData?.recurring || false,
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
          <label className="text-sm font-medium">Solicitante</label>
          <Input
            required
            placeholder="Nome de quem abriu o chamado"
            value={formData.requesterName}
            onChange={e => setFormData({ ...formData, requesterName: e.target.value })}
          />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Setor</label>
          <Input
            required
            placeholder="Ex: Escritório, Barracão..."
            value={formData.sector}
            onChange={e => setFormData({ ...formData, sector: e.target.value })}
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Categoria</label>
          <select
            className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            value={formData.category}
            onChange={e => setFormData({ ...formData, category: e.target.value })}
          >
            {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Prioridade</label>
          <select
            className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            value={formData.priority}
            onChange={e => setFormData({ ...formData, priority: e.target.value })}
          >
            <option value="BAIXA">Baixa</option>
            <option value="MEDIA">Média</option>
            <option value="ALTA">Alta</option>
            <option value="CRITICA">Crítica</option>
          </select>
        </div>
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium">Descrição do Problema</label>
        <textarea
          required
          className="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
          placeholder="Descreva o que está acontecendo..."
          value={formData.description}
          onChange={e => setFormData({ ...formData, description: e.target.value })}
        />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Equipamento Relacionado</label>
          <select
            className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            value={formData.assetId}
            onChange={e => setFormData({ ...formData, assetId: e.target.value })}
          >
            <option value="">Nenhum</option>
            {assets.map(a => (
              <option key={a.id} value={a.id}>{a.tag} - {a.name}</option>
            ))}
          </select>
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Status</label>
          <select
            className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            value={formData.status}
            onChange={e => setFormData({ ...formData, status: e.target.value })}
          >
            <option value="ABERTO">Aberto</option>
            <option value="EM_ANDAMENTO">Em Andamento</option>
            <option value="AGUARDANDO_PECA">Aguardando Peça</option>
            <option value="CONCLUIDO">Concluído</option>
          </select>
        </div>
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium">Solução Aplicada (opcional)</label>
        <textarea
          className="flex min-h-[60px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
          placeholder="O que foi feito para resolver..."
          value={formData.solution}
          onChange={e => setFormData({ ...formData, solution: e.target.value })}
        />
      </div>

      <label className="flex items-center gap-2 text-sm font-medium">
        <input
          type="checkbox"
          checked={formData.recurring}
          onChange={e => setFormData({ ...formData, recurring: e.target.checked })}
        />
        Problema recorrente (já aconteceu antes)
      </label>

      <div className="flex justify-end gap-3 pt-4 border-t">
        <Button variant="outline" type="button" onClick={onCancel}>Cancelar</Button>
        <Button type="submit" disabled={loading}>
          {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : initialData ? "Atualizar" : "Abrir"} Chamado
        </Button>
      </div>
    </form>
  )
}
