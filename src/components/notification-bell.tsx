"use client"

import * as React from "react"
import Link from "next/link"
import { Bell, AlertTriangle, FileWarning, CheckCircle2 } from "lucide-react"
import { Button } from "@/components/ui/button"

interface Notification {
  id: string
  type: "sla" | "document"
  title: string
  description: string
  href: string
  severity: "critical" | "warning"
}

export function NotificationBell() {
  const [isOpen, setIsOpen] = React.useState(false)
  const [notifications, setNotifications] = React.useState<Notification[]>([])
  const [loading, setLoading] = React.useState(true)
  const ref = React.useRef<HTMLDivElement>(null)

  React.useEffect(() => {
    async function fetchNotifications() {
      try {
        const res = await fetch("/api/notifications")
        const data = await res.json()
        setNotifications(data.notifications || [])
      } catch {
        // silencioso: sino sem dado não deve quebrar o topbar
      } finally {
        setLoading(false)
      }
    }
    fetchNotifications()
    const interval = setInterval(fetchNotifications, 60000)
    return () => clearInterval(interval)
  }, [])

  React.useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setIsOpen(false)
    }
    document.addEventListener("mousedown", handleClickOutside)
    return () => document.removeEventListener("mousedown", handleClickOutside)
  }, [])

  const criticalCount = notifications.filter((n) => n.severity === "critical").length

  return (
    <div className="relative" ref={ref}>
      <Button
        variant="ghost"
        size="icon"
        className="relative h-9 w-9 text-zinc-400 hover:text-zinc-200"
        onClick={() => setIsOpen((v) => !v)}
      >
        <Bell className="h-4 w-4" />
        {notifications.length > 0 && (
          <span className="absolute right-1.5 top-1.5 flex h-4 min-w-[16px] items-center justify-center rounded-full px-1 text-[9px] font-bold text-white" style={{ background: criticalCount > 0 ? "#ef4444" : "#f59e0b" }}>
            {notifications.length > 9 ? "9+" : notifications.length}
          </span>
        )}
      </Button>

      {isOpen && (
        <div
          className="absolute right-0 top-full mt-2 w-80 rounded-xl shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-150 z-50"
          style={{ background: "var(--modal-bg)", border: "1px solid var(--modal-border)" }}
        >
          <div className="px-4 py-3 border-b flex items-center justify-between" style={{ borderColor: "var(--modal-border)" }}>
            <p className="text-sm font-semibold" style={{ color: "var(--text-primary)" }}>Notificações</p>
            {notifications.length > 0 && (
              <span className="text-[10px]" style={{ color: "var(--text-tertiary)" }}>{notifications.length} pendente(s)</span>
            )}
          </div>
          <div className="max-h-80 overflow-y-auto">
            {loading ? (
              <p className="px-4 py-6 text-sm text-center" style={{ color: "var(--text-tertiary)" }}>Carregando...</p>
            ) : notifications.length === 0 ? (
              <div className="px-4 py-8 text-center">
                <CheckCircle2 className="h-8 w-8 mx-auto mb-2 text-emerald-500" />
                <p className="text-sm" style={{ color: "var(--text-tertiary)" }}>Tudo em dia. Nenhum alerta agora.</p>
              </div>
            ) : (
              notifications.map((n) => (
                <Link
                  key={n.id}
                  href={n.href}
                  onClick={() => setIsOpen(false)}
                  className="flex items-start gap-3 px-4 py-3 transition-colors hover:bg-[var(--sidebar-item-hover)] border-b last:border-0"
                  style={{ borderColor: "var(--modal-border)" }}
                >
                  {n.type === "sla" ? (
                    <AlertTriangle className={`h-4 w-4 mt-0.5 flex-shrink-0 ${n.severity === "critical" ? "text-red-500" : "text-amber-500"}`} />
                  ) : (
                    <FileWarning className={`h-4 w-4 mt-0.5 flex-shrink-0 ${n.severity === "critical" ? "text-red-500" : "text-amber-500"}`} />
                  )}
                  <div className="min-w-0">
                    <p className="text-sm font-medium" style={{ color: "var(--text-primary)" }}>{n.title}</p>
                    <p className="text-xs truncate" style={{ color: "var(--text-tertiary)" }}>{n.description}</p>
                  </div>
                </Link>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  )
}

