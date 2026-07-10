"use client"

import React from "react"
import { FileText, AlertTriangle, CheckCircle2, Plus, Loader2, Pencil, Trash2, RefreshCw } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Modal } from "@/components/ui/modal"
import { cn } from "@/lib/utils"
import { DocumentForm } from "@/components/features/documents/DocumentForm"
import { useConfirm } from "@/components/confirm-dialog-provider"
import { useToast } from "@/components/toast-provider"

function daysUntil(date: string) {
  const diff = new Date(date).getTime() - Date.now()
  return Math.ceil(diff / (1000 * 60 * 60 * 24))
}

export default function DocumentsPage() {
  const confirmDialog = useConfirm()
  const { success, error: toastError } = useToast()
  const [documents, setDocuments] = React.useState<any[]>([])
  const [suppliers, setSuppliers] = React.useState<any[]>([])
  const [assets, setAssets] = React.useState<any[]>([])
  const [loading, setLoading] = React.useState(true)
  const [isModalOpen, setIsModalOpen] = React.useState(false)
  const [editingDoc, setEditingDoc] = React.useState<any>(null)

  const fetchData = React.useCallback(async () => {
    setLoading(true)
    try {
      const [dRes, sRes, aRes] = await Promise.all([
        fetch("/api/documents"),
        fetch("/api/suppliers"),
        fetch("/api/assets"),
      ])
      const dData = await dRes.json()
      const sData = await sRes.json()
      const aData = await aRes.json()
      if (Array.isArray(dData)) setDocuments(dData)
      if (Array.isArray(sData)) setSuppliers(sData)
      if (Array.isArray(aData)) setAssets(aData)
    } catch (error) {
      console.error("Error fetching documents:", error)
    } finally {
      setLoading(false)
    }
  }, [])

  React.useEffect(() => { fetchData() }, [fetchData])

  async function handleCreateOrUpdate(data: any) {
    const url = editingDoc ? `/api/documents/${editingDoc.id}` : "/api/documents"
    const method = editingDoc ? "PUT" : "POST"
    try {
      const res = await fetch(url, {
        method,
        body: JSON.stringify(data),
        headers: { "Content-Type": "application/json" },
      })
      if (res.ok) {
        setIsModalOpen(false)
        setEditingDoc(null)
        success(editingDoc ? "Registro atualizado" : "Registro cadastrado")
        fetchData()
      } else {
        const result = await res.json().catch(() => null)
        toastError(result?.error || "Erro ao salvar registro")
      }
    } catch (error) {
      console.error("Error saving document:", error)
      toastError("Erro ao salvar registro")
    }
  }

  async function handleDelete(id: string) {
    const ok = await confirmDialog({ title: "Excluir certificado/licença", message: "Deseja realmente excluir este registro? Essa ação não pode ser desfeita.", destructive: true })
    if (!ok) return
    try {
      const res = await fetch(`/api/documents/${id}`, { method: "DELETE" })
      if (res.ok) {
        success("Registro excluído")
        fetchData()
      } else {
        const result = await res.json().catch(() => null)
        toastError(result?.error || "Erro ao excluir registro")
      }
    } catch (error) {
      console.error("Error deleting document:", error)
      toastError("Erro ao excluir registro")
    }
  }

  const expiredCount = documents.filter(d => daysUntil(d.validUntil) < 0).length
  const expiringSoonCount = documents.filter(d => { const days = daysUntil(d.validUntil); return days >= 0 && days <= 60 }).length
  const okCount = documents.filter(d => daysUntil(d.validUntil) > 60).length

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Certificados e Licenças</h1>
          <p className="text-muted-foreground">Controle de vencimento de certificados digitais e licenças de software.</p>
        </div>
        <Button className="bg-primary shadow-lg shadow-primary/20" onClick={() => { setEditingDoc(null); setIsModalOpen(true) }}>
          <Plus className="mr-2 h-4 w-4" />
          Cadastrar
        </Button>
      </div>

      <div className="grid gap-6 md:grid-cols-3">
        <Card className="bg-red-500/5 border-red-500/20">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <AlertTriangle className="h-4 w-4 text-red-500" /> Vencidos
            </CardTitle>
          </CardHeader>
          <CardContent><div className="text-2xl font-bold">{String(expiredCount).padStart(2, '0')}</div></CardContent>
        </Card>
        <Card className="bg-amber-500/5 border-amber-500/20">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <AlertTriangle className="h-4 w-4 text-amber-500" /> Vencendo em 60 dias
            </CardTitle>
          </CardHeader>
          <CardContent><div className="text-2xl font-bold">{String(expiringSoonCount).padStart(2, '0')}</div></CardContent>
        </Card>
        <Card className="bg-emerald-500/5 border-emerald-500/20">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <CheckCircle2 className="h-4 w-4 text-emerald-500" /> Em dia
            </CardTitle>
          </CardHeader>
          <CardContent><div className="text-2xl font-bold">{String(okCount).padStart(2, '0')}</div></CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Lista</CardTitle>
            <CardDescription>Ordenado por data de vencimento mais próxima.</CardDescription>
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
            ) : documents.length === 0 ? (
              <div className="p-12 text-center text-muted-foreground">Nenhum certificado ou licença cadastrado.</div>
            ) : (
              documents.map((d) => {
                const days = daysUntil(d.validUntil)
                const statusColor = days < 0 ? "text-red-500 bg-red-500/10" : days <= 60 ? "text-amber-500 bg-amber-500/10" : "text-emerald-500 bg-emerald-500/10"
                return (
                  <div key={d.id} className="p-4 hover:bg-muted/50 transition-colors flex items-center justify-between group">
                    <div className="flex items-center gap-4">
                      <div className={cn("p-2 rounded-full", statusColor)}>
                        <FileText className="h-5 w-5" />
                      </div>
                      <div>
                        <div className="flex items-center gap-2 flex-wrap">
                          <p className="font-semibold text-sm">{d.title}</p>
                          <Badge variant="outline" className="text-[10px] font-normal py-0 h-4">
                            {d.type === "CERTIFICADO" ? "Certificado" : "Licença"}
                          </Badge>
                        </div>
                        <p className="text-xs text-muted-foreground mt-1">
                          {d.holder} — vence em {new Date(d.validUntil).toLocaleDateString()}
                          {" "}({days < 0 ? `vencido há ${Math.abs(days)} dias` : `${days} dias`})
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-8 w-8 text-muted-foreground hover:text-primary"
                        aria-label="Editar certificado/licença"
                        onClick={() => { setEditingDoc(d); setIsModalOpen(true) }}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-8 w-8 text-destructive hover:text-destructive"
                        aria-label="Excluir certificado/licença"
                        onClick={() => handleDelete(d.id)}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                )
              })
            )}
          </div>
        </CardContent>
      </Card>

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingDoc ? "Editar Registro" : "Novo Certificado/Licença"}>
        <DocumentForm
          initialData={editingDoc}
          suppliers={suppliers}
          assets={assets}
          onCancel={() => setIsModalOpen(false)}
          onSubmit={handleCreateOrUpdate}
        />
      </Modal>
    </div>
  )
}
