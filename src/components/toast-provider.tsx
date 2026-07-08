"use client"

import * as React from "react"
import { Toast, type ToastType } from "@/components/ui/toast"

interface ToastItem {
  id: number
  type: ToastType
  title: string
  description?: string
}

interface ToastContextValue {
  notify: (title: string, options?: { type?: ToastType; description?: string }) => void
  success: (title: string, description?: string) => void
  error: (title: string, description?: string) => void
}

const ToastContext = React.createContext<ToastContextValue | null>(null)

export function ToastQueueProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = React.useState<ToastItem[]>([])
  const idRef = React.useRef(0)

  const notify = React.useCallback((title: string, options?: { type?: ToastType; description?: string }) => {
    const id = ++idRef.current
    setItems((prev) => [...prev, { id, title, type: options?.type || "info", description: options?.description }])
  }, [])

  const success = React.useCallback((title: string, description?: string) => notify(title, { type: "success", description }), [notify])
  const error = React.useCallback((title: string, description?: string) => notify(title, { type: "error", description }), [notify])

  function dismiss(id: number) {
    setItems((prev) => prev.filter((t) => t.id !== id))
  }

  return (
    <ToastContext.Provider value={{ notify, success, error }}>
      {children}
      <div className="fixed bottom-4 right-4 z-[100] flex flex-col gap-2 w-full max-w-sm">
        {items.map((item) => (
          <Toast
            key={item.id}
            type={item.type}
            title={item.title}
            description={item.description}
            onClose={() => dismiss(item.id)}
          />
        ))}
      </div>
    </ToastContext.Provider>
  )
}

export function useToast() {
  const ctx = React.useContext(ToastContext)
  if (!ctx) throw new Error("useToast precisa estar dentro de <ToastQueueProvider>")
  return ctx
}

