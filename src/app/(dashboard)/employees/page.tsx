"use client"

import React from "react"
import {
  Search,
  Mail,
  Phone,
  Pencil,
  Trash2,
  UserPlus,
  Loader2,
  RefreshCcw
} from "lucide-react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { useConfirm } from "@/components/confirm-dialog-provider"
import { useToast } from "@/components/toast-provider"
import { EmployeeForm } from "@/components/features/employees/EmployeeForm"

export default function EmployeesPage() {
  const confirmDialog = useConfirm()
  const { success, error: toastError } = useToast()
  const [employees, setEmployees] = React.useState<any[]>([])
  const [loading, setLoading] = React.useState(true)
  const [searchTerm, setSearchTerm] = React.useState("")
  const [isModalOpen, setIsModalOpen] = React.useState(false)
  const [editingEmployee, setEditingEmployee] = React.useState<any>(null)
  const [error, setError] = React.useState<string | null>(null)

  const fetchEmployees = React.useCallback(async () => {
    setLoading(true)
    try {
      const res = await fetch("/api/employees")
      const data = await res.json()
      if (Array.isArray(data)) setEmployees(data)
    } catch (error) {
      console.error("Error fetching employees:", error)
    } finally {
      setLoading(false)
    }
  }, [])

  React.useEffect(() => {
    fetchEmployees()
  }, [fetchEmployees])

  async function handleCreateOrUpdate(data: any) {
    setError(null)
    const url = editingEmployee ? `/api/employees/${editingEmployee.id}` : "/api/employees"
    const method = editingEmployee ? "PUT" : "POST"
    try {
      const res = await fetch(url, {
        method,
        body: JSON.stringify(data),
        headers: { "Content-Type": "application/json" },
      })
      const result = await res.json()
      if (res.ok) {
        setIsModalOpen(false)
        setEditingEmployee(null)
        success(editingEmployee ? "Colaborador atualizado" : "Colaborador criado")
        fetchEmployees()
      } else {
        setError(result.error || "Erro ao salvar colaborador")
      }
    } catch (err) {
      console.error("Error saving employee:", err)
      setError("Erro ao salvar colaborador")
    }
  }

  async function handleDelete(id: string) {
    const ok = await confirmDialog({ title: "Excluir colaborador", message: "Deseja realmente excluir este colaborador?", destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/employees/${id}`, { method: "DELETE" })
      const result = await res.json()
      if (res.ok) {
        success("Colaborador excluído")
        fetchEmployees()
      } else {
        toastError(result.error || "Erro ao excluir colaborador")
      }
    } catch (error) {
      console.error("Error deleting employee:", error)
      toastError("Erro ao excluir colaborador")
    }
  }

  const filtered = employees.filter(emp =>
    emp.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    emp.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (emp.department || "").toLowerCase().includes(searchTerm.toLowerCase())
  )

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Colaboradores</h1>
          <p className="text-muted-foreground">Gerencie o inventário de ativos por pessoa e departamento.</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={fetchEmployees} disabled={loading}>
            <RefreshCcw className={loading ? "mr-2 h-4 w-4 animate-spin" : "mr-2 h-4 w-4"} />
            Sincronizar
          </Button>
          <Button
            className="bg-primary shadow-lg shadow-primary/20"
            onClick={() => { setEditingEmployee(null); setError(null); setIsModalOpen(true) }}
          >
            <UserPlus className="mr-2 h-4 w-4" />
            Novo Colaborador
          </Button>
        </div>
      </div>

      <div className="relative flex-1 w-full">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Buscar por nome, e-mail ou setor..."
          className="pl-10 h-11"
          value={searchTerm}
          onChange={e => setSearchTerm(e.target.value)}
        />
      </div>

      <Card>
        <CardContent className="p-0">
          <div className="relative w-full overflow-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-muted/30">
                  <th className="h-12 px-4 text-left font-medium text-muted-foreground">Colaborador</th>
                  <th className="h-12 px-4 text-left font-medium text-muted-foreground">Cargo / Setor</th>
                  <th className="h-12 px-4 text-left font-medium text-muted-foreground">Nível</th>
                  <th className="h-12 px-4 text-center font-medium text-muted-foreground">Ativos</th>
                  <th className="h-12 px-4 text-left font-medium text-muted-foreground">Status</th>
                  <th className="h-12 px-4 text-right font-medium text-muted-foreground">Ações</th>
                </tr>
              </thead>
              <tbody className="[&_tr:last-child]:border-0">
                {loading ? (
                  <tr>
                    <td colSpan={6} className="p-8 text-center">
                      <Loader2 className="h-8 w-8 animate-spin mx-auto text-primary" />
                    </td>
                  </tr>
                ) : filtered.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="p-8 text-center text-muted-foreground">
                      Nenhum colaborador encontrado.
                    </td>
                  </tr>
                ) : filtered.map((person) => (
                  <tr key={person.id} className="border-b transition-colors hover:bg-muted/50 group">
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold">
                          {person.name[0]}
                        </div>
                        <div>
                          <p className="font-semibold leading-none">{person.name}</p>
                          <p className="text-xs text-muted-foreground mt-1 flex items-center gap-1">
                            <Mail className="h-3 w-3" /> {person.email}
                          </p>
                          {person.phone && (
                            <p className="text-xs text-muted-foreground mt-0.5 flex items-center gap-1">
                              <Phone className="h-3 w-3" /> {person.phone}
                            </p>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="p-4 align-middle">
                      <p className="text-sm">{person.jobTitle || "—"}</p>
                      <p className="text-xs text-muted-foreground">{person.department || "Sem setor"}</p>
                    </td>
                    <td className="p-4 align-middle">
                      <Badge variant="secondary" className="font-normal">{person.role}</Badge>
                    </td>
                    <td className="p-4 text-center">
                      <div className="inline-flex items-center justify-center h-7 w-7 rounded-full bg-zinc-100 dark:bg-zinc-800 font-bold">
                        {person._count?.assets || 0}
                      </div>
                    </td>
                    <td className="p-4">
                      <Badge variant={person.status === "INATIVO" ? "outline" : "success"}>
                        {person.status || "ATIVO"}
                      </Badge>
                    </td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8 text-muted-foreground hover:text-primary"
                          onClick={() => { setEditingEmployee(person); setError(null); setIsModalOpen(true) }}
                        >
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8 text-destructive hover:text-destructive"
                          onClick={() => handleDelete(person.id)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingEmployee ? "Editar Colaborador" : "Novo Colaborador"}
      >
        {error && (
          <div className="mb-4 p-3 rounded-md bg-red-500/10 border border-red-500/20 text-sm text-red-500">
            {error}
          </div>
        )}
        <EmployeeForm
          initialData={editingEmployee}
          onCancel={() => setIsModalOpen(false)}
          onSubmit={handleCreateOrUpdate}
        />
      </Modal>
    </div>
  )
}

