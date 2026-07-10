"use client"

import React from "react"
import { Building2, Phone, Mail, Plus, Loader2, Pencil, Trash2, RefreshCw } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { EmptyState } from "@/components/ui/empty-state"
import { SupplierForm } from "@/components/features/suppliers/SupplierForm"
import { useConfirm } from "@/components/confirm-dialog-provider"
import { useToast } from "@/components/toast-provider"

export default function SuppliersPage() {
  const confirmDialog = useConfirm()
  const { success, error: toastError } = useToast()
  const [suppliers, setSuppliers] = React.useState<any[]>([])
  const [loading, setLoading] = React.useState(true)
  const [isModalOpen, setIsModalOpen] = React.useState(false)
  const [editingSupplier, setEditingSupplier] = React.useState<any>(null)

  const fetchData = React.useCallback(async () => {
    setLoading(true)
    try {
      const res = await fetch("/api/suppliers")
      const data = await res.json()
      if (Array.isArray(data)) setSuppliers(data)
    } catch (error) {
      console.error("Error fetching suppliers:", error)
    } finally {
      setLoading(false)
    }
  }, [])

  React.useEffect(() => { fetchData() }, [fetchData])

  async function handleCreateOrUpdate(data: any) {
    const url = editingSupplier ? `/api/suppliers/${editingSupplier.id}` : "/api/suppliers"
    const method = editingSupplier ? "PUT" : "POST"
    try {
      const res = await fetch(url, { method, body: JSON.stringify(data), headers: { "Content-Type": "application/json" } })
      if (res.ok) {
        setIsModalOpen(false); setEditingSupplier(null)
        success(editingSupplier ? "Fornecedor atualizado" : "Fornecedor cadastrado"); fetchData()
      } else {
        const result = await res.json().catch(() => null)
        toastError(result?.error || "Erro ao salvar fornecedor")
      }
    } catch { toastError("Erro ao salvar fornecedor") }
  }

  async function handleDelete(id: string) {
    const ok = await confirmDialog({ title: "Excluir fornecedor", message: "Deseja realmente excluir este fornecedor? Essa ação não pode ser desfeita.", destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/suppliers/${id}`, { method: "DELETE" })
      if (res.ok) { success("Fornecedor excluído"); fetchData() }
      else { const r = await res.json().catch(()=>null); toastError(r?.error || "Erro ao excluir") }
    } catch { toastError("Erro ao excluir fornecedor") }
  }

  const openNewSupplier = () => { setEditingSupplier(null); setIsModalOpen(true) }

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Fornecedores</h1>
          <p className="text-muted-foreground">Contatos de suporte e contratos por tipo de serviço.</p>
        </div>
        <Button className="bg-primary shadow-lg shadow-primary/20" onClick={openNewSupplier}>
          <Plus className="mr-2 h-4 w-4" /> Novo Fornecedor
        </Button>
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div><CardTitle>Lista de Fornecedores</CardTitle><CardDescription>Quem resolve cada tipo de problema.</CardDescription></div>
          <Button variant="outline" size="sm" onClick={fetchData} disabled={loading}>
            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="mr-2 h-4 w-4" />} Sincronizar
          </Button>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y relative min-h-[300px]">
            {loading ? (
              <div className="absolute inset-0 flex items-center justify-center bg-background/50 backdrop-blur-[1px]">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
              </div>
            ) : suppliers.length === 0 ? (
              <EmptyState
                icon="🏢"
                title="Nenhum fornecedor cadastrado"
                description="Cadastre fornecedores de suporte e serviços para facilitar o acionamento na hora certa."
                action={<Button onClick={openNewSupplier}><Plus className="mr-2 h-4 w-4" />Cadastrar primeiro fornecedor</Button>}
              />
            ) : (
              suppliers.map((s) => (
                <div key={s.id} className="p-4 hover:bg-muted/50 transition-colors flex items-center justify-between group">
                  <div className="flex items-center gap-4">
                    <div className="p-2 rounded-full bg-primary/10 text-primary">
                      <Building2 className="h-5 w-5" />
                    </div>
                    <div>
                      <div className="flex items-center gap-2 flex-wrap">
                        <p className="font-semibold text-sm">{s.name}</p>
                        <Badge variant="outline" className="text-[10px] font-normal py-0 h-4">{s.serviceType}</Badge>
                        {s.hasContract && (
                          <Badge className="text-[10px] font-normal py-0 h-4 bg-emerald-500/10 text-emerald-500 border-emerald-500/20 border">Com contrato</Badge>
                        )}
                      </div>
                      <p className="text-xs text-muted-foreground mt-1 flex items-center gap-3">
                        {s.contactName && <span>{s.contactName}</span>}
                        {s.phone && <span className="flex items-center gap-1"><Phone className="h-3 w-3" />{s.phone}</span>}
                        {s.email && <span className="flex items-center gap-1"><Mail className="h-3 w-3" />{s.email}</span>}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Button variant="ghost" size="icon" className="h-8 w-8 text-muted-foreground hover:text-primary" aria-label="Editar fornecedor"
                      onClick={() => { setEditingSupplier(s); setIsModalOpen(true) }}><Pencil className="h-4 w-4" /></Button>
                    <Button variant="ghost" size="icon" className="h-8 w-8 text-destructive hover:text-destructive" aria-label="Excluir fornecedor"
                      onClick={() => handleDelete(s.id)}><Trash2 className="h-4 w-4" /></Button>
                  </div>
                </div>
              ))
            )}
          </div>
        </CardContent>
      </Card>

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingSupplier ? "Editar Fornecedor" : "Novo Fornecedor"}>
        <SupplierForm initialData={editingSupplier} onCancel={() => setIsModalOpen(false)} onSubmit={handleCreateOrUpdate} />
      </Modal>
    </div>
  )
}
"use client"

import React from "react"
import { Building2, Phone, Mail, Plus, Loader2, Pencil, Trash2, RefreshCw } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { SupplierForm } from "@/components/features/suppliers/SupplierForm"
import { useConfirm } from "@/components/confirm-dialog-provider"
import { useToast } from "@/components/toast-provider"

export default function SuppliersPage() {
  const confirmDialog = useConfirm()
  const { success, error: toastError } = useToast()
  const [suppliers, setSuppliers] = React.useState<any[]>([])
  const [loading, setLoading] = React.useState(true)
  const [isModalOpen, setIsModalOpen] = React.useState(false)
  const [editingSupplier, setEditingSupplier] = React.useState<any>(null)

  const fetchData = React.useCallback(async () => {
    setLoading(true)
    try {
      const res = await fetch("/api/suppliers")
      const data = await res.json()
      if (Array.isArray(data)) setSuppliers(data)
    } catch (error) {
      console.error("Error fetching suppliers:", error)
    } finally {
      setLoading(false)
    }
  }, [])

  React.useEffect(() => { fetchData() }, [fetchData])

  async function handleCreateOrUpdate(data: any) {
    const url = editingSupplier ? `/api/suppliers/${editingSupplier.id}` : "/api/suppliers"
    const method = editingSupplier ? "PUT" : "POST"
    try {
      const res = await fetch(url, {
        method,
        body: JSON.stringify(data),
        headers: { "Content-Type": "application/json" },
      })
      if (res.ok) {
        setIsModalOpen(false)
        setEditingSupplier(null)
        success(editingSupplier ? "Fornecedor atualizado" : "Fornecedor cadastrado")
        fetchData()
      } else {
        const result = await res.json().catch(() => null)
        toastError(result?.error || "Erro ao salvar fornecedor")
      }
    } catch (error) {
      console.error("Error saving supplier:", error)
      toastError("Erro ao salvar fornecedor")
    }
  }

  async function handleDelete(id: string) {
    const ok = await confirmDialog({ title: "Excluir fornecedor", message: "Deseja realmente excluir este fornecedor? Essa ação não pode ser desfeita.", destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/suppliers/${id}`, { method: "DELETE" })
      if (res.ok) {
        success("Fornecedor excluído")
        fetchData()
      } else {
        const result = await res.json().catch(() => null)
        toastError(result?.error || "Erro ao excluir fornecedor")
      }
    } catch (error) {
      console.error("Error deleting supplier:", error)
      toastError("Erro ao excluir fornecedor")
    }
  }

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Fornecedores</h1>
          <p className="text-muted-foreground">Contatos de suporte e contratos por tipo de serviço.</p>
        </div>
        <Button className="bg-primary shadow-lg shadow-primary/20" onClick={() => { setEditingSupplier(null); setIsModalOpen(true) }}>
          <Plus className="mr-2 h-4 w-4" />
          Novo Fornecedor
        </Button>
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Lista de Fornecedores</CardTitle>
            <CardDescription>Quem resolve cada tipo de problema.</CardDescription>
          </div>
          <Button variant="outline" size="sm" onClick={fetchData} disabled={loading}>
            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="mr-2 h-4 w-4" />}
            Sincronizar
          </Button>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y relative min-h-[300px]">
            {loading ? (
              <div className="absolute inset-0 flex items-center justify-center bg-background/50 backdrop-blur-[1px]">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
              </div>
            ) : suppliers.length === 0 ? (
              <div className="p-12 text-center text-muted-foreground">Nenhum fornecedor cadastrado.</div>
            ) : (
              suppliers.map((s) => (
                <div key={s.id} className="p-4 hover:bg-muted/50 transition-colors flex items-center justify-between group">
                  <div className="flex items-center gap-4">
                    <div className="p-2 rounded-full bg-primary/10 text-primary">
                      <Building2 className="h-5 w-5" />
                    </div>
                    <div>
                      <div className="flex items-center gap-2 flex-wrap">
                        <p className="font-semibold text-sm">{s.name}</p>
                        <Badge variant="outline" className="text-[10px] font-normal py-0 h-4">{s.serviceType}</Badge>
                        {s.hasContract && (
                          <Badge className="text-[10px] font-normal py-0 h-4 bg-emerald-500/10 text-emerald-500 border-emerald-500/20 border">
                            Com contrato
                          </Badge>
                        )}
                      </div>
                      <p className="text-xs text-muted-foreground mt-1 flex items-center gap-3">
                        {s.contactName && <span>{s.contactName}</span>}
                        {s.phone && <span className="flex items-center gap-1"><Phone className="h-3 w-3" />{s.phone}</span>}
                        {s.email && <span className="flex items-center gap-1"><Mail className="h-3 w-3" />{s.email}</span>}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 text-muted-foreground hover:text-primary"
                      aria-label="Editar fornecedor"
                      onClick={() => { setEditingSupplier(s); setIsModalOpen(true) }}
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 text-destructive hover:text-destructive"
                      aria-label="Excluir fornecedor"
                      onClick={() => handleDelete(s.id)}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              ))
            )}
          </div>
        </CardContent>
      </Card>

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingSupplier ? "Editar Fornecedor" : "Novo Fornecedor"}>
        <SupplierForm
          initialData={editingSupplier}
          onCancel={() => setIsModalOpen(false)}
          onSubmit={handleCreateOrUpdate}
        />
      </Modal>
    </div>
  )
}
