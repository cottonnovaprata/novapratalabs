"use client"

import * as React from "react"
import { AlertTriangle } from "lucide-react"
import { Button } from "@/components/ui/button"

interface ConfirmOptions {
  title?: string
  message: string
  confirmLabel?: string
  cancelLabel?: string
  destructive?: boolean
}

interface PendingConfirm extends ConfirmOptions {
  resolve: (value: boolean) => void
}

interface ConfirmContextValue {
  confirm: (options: ConfirmOptions | string) => Promise<boolean>
}

const ConfirmContext = React.createContext<ConfirmContextValue | null>(null)

export function ConfirmDialogProvider({ children }: { children: React.ReactNode }) {
  const [pending, setPending] = React.useState<PendingConfirm | null>(null)

  const confirm = React.useCallback((options: ConfirmOptions | string) => {
    const normalized: ConfirmOptions = typeof options === "string" ? { message: options } : options
    return new Promise<boolean>((resolve) => {
      setPending({ ...normalized, resolve })
    })
  }, [])

  function handle(result: boolean) {
    pending?.resolve(result)
    setPending(null)
  }

  React.useEffect(() => {
    function handleEscape(e: KeyboardEvent) {
      if (e.key === "Escape" && pending) handle(false)
    }
    document.addEventListener("keydown", handleEscape)
    return () => document.removeEventListener("keydown", handleEscape)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pending])

  return (
    <ConfirmContext.Provider value={{ confirm }}>
      {children}
      {pending && (
        <div className="fixed inset-0 z-[110] flex items-center justify-center p-4 backdrop-blur-sm animate-in fade-in duration-200" style={{ background: "var(--modal-overlay)" }}>
          <div
            className="w-full max-w-sm rounded-xl shadow-2xl overflow-hidden animate-in zoom-in-95 duration-200"
            style={{ background: "var(--modal-bg)", border: "1px solid var(--modal-border)" }}
          >
            <div className="p-6 flex gap-4">
              <div
                className="h-10 w-10 rounded-full flex items-center justify-center flex-shrink-0"
                style={{
                  background: pending.destructive ? "var(--status-error-bg)" : "var(--status-warning-bg)",
                  color: pending.destructive ? "var(--status-error)" : "var(--status-warning)",
                }}
              >
                <AlertTriangle className="h-5 w-5" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold text-base" style={{ color: "var(--text-primary)" }}>
                  {pending.title || "Confirmar ação"}
                </h3>
                <p className="text-sm mt-1.5" style={{ color: "var(--text-tertiary)" }}>
                  {pending.message}
                </p>
              </div>
            </div>
            <div className="flex justify-end gap-2 px-6 py-4 border-t" style={{ borderColor: "var(--modal-border)" }}>
              <Button variant="outline" size="sm" onClick={() => handle(false)}>
                {pending.cancelLabel || "Cancelar"}
              </Button>
              <Button
                variant={pending.destructive ? "destructive" : "default"}
                size="sm"
                onClick={() => handle(true)}
              >
                {pending.confirmLabel || "Confirmar"}
              </Button>
            </div>
          </div>
        </div>
      )}
    </ConfirmContext.Provider>
  )
}

export function useConfirm() {
  const ctx = React.useContext(ConfirmContext)
  if (!ctx) throw new Error("useConfirm precisa estar dentro de <ConfirmDialogProvider>")
  return ctx.confirm
}

