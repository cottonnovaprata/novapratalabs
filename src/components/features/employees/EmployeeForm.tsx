"use client"

import * as React from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Loader2 } from "lucide-react"

interface EmployeeFormProps {
  initialData?: any
  onSubmit: (data: any) => Promise<void>
  onCancel: () => void
}

export function EmployeeForm({ initialData, onSubmit, onCancel }: EmployeeFormProps) {
  const [loading, setLoading] = React.useState(false)
  const [formData, setFormData] = React.useState({
    name: initialData?.name || "",
    email: initialData?.email || "",
    phone: initialData?.phone || "",
    department: initialData?.department || "",
    jobTitle: initialData?.jobTitle || "",
    role: initialData?.role || "USER",
    status: initialData?.status || "ATIVO",
    newPassword: "",
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
          <label className="text-sm font-medium">E-mail</label>
          <Input
            type="email"
            required
            disabled={!!initialData}
            value={formData.email}
            onChange={e => setFormData({ ...formData, email: e.target.value })}
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Telefone</label>
          <Input
            placeholder="(66) 99999-9999"
            value={formData.phone}
            onChange={e => setFormData({ ...formData, phone: e.target.value })}
          />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Cargo</label>
          <Input value={formData.jobTitle} onChange={e => setFormData({ ...formData, jobTitle: e.target.value })} />
        </div>
      </div>

      <div className="grid grid-cols-3 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Setor</label>
          <Input
            placeholder="Escritório, Barracão..."
            value={formData.department}
            onChange={e => setFormData({ ...formData, department: e.target.value })}
          />
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Nível de Acesso</label>
          <select
            className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            value={formData.role}
            onChange={e => setFormData({ ...formData, role: e.target.value })}
          >
            <option value="USER">Usuário</option>
            <option value="TECHNICIAN">Técnico</option>
            <option value="ADMIN">Admin</option>
          </select>
        </div>
        <div className="space-y-2">
          <label className="text-sm font-medium">Status</label>
          <select
            className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            value={formData.status}
            onChange={e => setFormData({ ...formData, status: e.target.value })}
          >
            <option value="ATIVO">Ativo</option>
            <option value="INATIVO">Inativo</option>
          </select>
        </div>
      </div>

      {initialData ? (
        <div className="space-y-2 pt-2 border-t">
          <label className="text-sm font-medium">Definir nova senha de acesso</label>
          <Input
            type="password"
            placeholder="Deixe em branco para não alterar"
            value={formData.newPassword}
            onChange={e => setFormData({ ...formData, newPassword: e.target.value })}
          />
          <p className="text-xs text-muted-foreground">
            Use isso pra dar acesso a um colaborador que ainda não consegue entrar no sistema. Avise a senha por um canal seguro (não por aqui).
          </p>
        </div>
      ) : (
        <p className="text-xs text-muted-foreground">
          O colaborador é criado com uma senha temporária aleatória. Depois de criar, edite o cadastro dele pra definir uma senha de acesso e avisá-lo.
        </p>
      )}

      <div className="flex justify-end gap-3 pt-4 border-t">
        <Button variant="outline" type="button" onClick={onCancel}>Cancelar</Button>
        <Button type="submit" disabled={loading}>
          {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : initialData ? "Salvar" : "Criar Colaborador"}
        </Button>
      </div>
    </form>
  )
}

