"use client"

import React from "react"
import { KeyRound, Loader2, ShieldCheck, User } from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

export default function SettingsPage() {
  const [form, setForm] = React.useState({ currentPassword: "", newPassword: "", confirmPassword: "" })
  const [loading, setLoading] = React.useState(false)
  const [message, setMessage] = React.useState<{ type: "success" | "error"; text: string } | null>(null)

  async function handleChangePassword(e: React.FormEvent) {
    e.preventDefault()
    setMessage(null)

    if (form.newPassword !== form.confirmPassword) {
      setMessage({ type: "error", text: "A confirmação não confere com a nova senha." })
      return
    }

    setLoading(true)
    try {
      const res = await fetch("/api/auth/change-password", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          currentPassword: form.currentPassword,
          newPassword: form.newPassword,
        }),
      })
      const data = await res.json().catch(() => ({}))
      if (!res.ok) {
        throw new Error(data.error || "Erro ao trocar senha")
      }
      setMessage({ type: "success", text: "Senha atualizada com sucesso." })
      setForm({ currentPassword: "", newPassword: "", confirmPassword: "" })
    } catch (err) {
      setMessage({ type: "error", text: err instanceof Error ? err.message : "Erro inesperado" })
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Configurações</h1>
        <p className="text-muted-foreground">Ajustes gerais da plataforma e preferências de uso.</p>
      </div>

      <Card className="max-w-xl">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <KeyRound className="h-5 w-5 text-primary" /> Trocar Senha
          </CardTitle>
          <CardDescription>Atualize sua própria senha de acesso ao sistema.</CardDescription>
        </CardHeader>
        <CardContent>
          {message && (
            <div
              className={
                message.type === "success"
                  ? "mb-4 p-3 rounded-md bg-emerald-500/10 border border-emerald-500/20 text-sm text-emerald-500"
                  : "mb-4 p-3 rounded-md bg-red-500/10 border border-red-500/20 text-sm text-red-500"
              }
            >
              {message.text}
            </div>
          )}
          <form onSubmit={handleChangePassword} className="space-y-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">Senha atual</label>
              <Input
                type="password"
                required
                value={form.currentPassword}
                onChange={e => setForm({ ...form, currentPassword: e.target.value })}
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Nova senha</label>
                <Input
                  type="password"
                  required
                  minLength={6}
                  value={form.newPassword}
                  onChange={e => setForm({ ...form, newPassword: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Confirmar nova senha</label>
                <Input
                  type="password"
                  required
                  minLength={6}
                  value={form.confirmPassword}
                  onChange={e => setForm({ ...form, confirmPassword: e.target.value })}
                />
              </div>
            </div>
            <div className="flex justify-end pt-2">
              <Button type="submit" disabled={loading}>
                {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <ShieldCheck className="mr-2 h-4 w-4" />}
                Atualizar Senha
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      <Card className="max-w-xl">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <User className="h-5 w-5 text-muted-foreground" /> Mais Configurações
          </CardTitle>
          <CardDescription>
            Preferências de notificação, tema padrão e integrações ficam aqui conforme forem implementadas.
          </CardDescription>
        </CardHeader>
      </Card>
    </div>
  )
}

