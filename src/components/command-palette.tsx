"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import {
  Search, LayoutDashboard, Box, Users, Lock, Network, PenTool,
  Ticket, FileText, Building2, BarChart3, Settings, Loader2, CornerDownLeft,
} from "lucide-react"

const NAV_COMMANDS = [
  { label: "Ir para Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { label: "Ir para Ativos", href: "/assets", icon: Box },
  { label: "Ir para Colaboradores", href: "/employees", icon: Users },
  { label: "Ir para Cofre", href: "/vault", icon: Lock },
  { label: "Ir para Rede", href: "/network", icon: Network },
  { label: "Ir para Manutenção", href: "/maintenances", icon: PenTool },
  { label: "Ir para Chamados", href: "/tickets", icon: Ticket },
  { label: "Ir para Certificados/Licenças", href: "/documents", icon: FileText },
  { label: "Ir para Fornecedores", href: "/suppliers", icon: Building2 },
  { label: "Ir para Relatórios", href: "/reports", icon: BarChart3 },
  { label: "Ir para Configurações", href: "/settings", icon: Settings },
]

interface SearchResult {
  type: string
  id: string
  label: string
  sublabel: string
  href: string
}

export function CommandPalette() {
  const [isOpen, setIsOpen] = React.useState(false)
  const [query, setQuery] = React.useState("")
  const [results, setResults] = React.useState<SearchResult[]>([])
  const [searching, setSearching] = React.useState(false)
  const inputRef = React.useRef<HTMLInputElement>(null)
  const router = useRouter()

  React.useEffect(() => {
    function handleKeydown(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault()
        setIsOpen((prev) => !prev)
      }
      if (e.key === "Escape") setIsOpen(false)
    }
    document.addEventListener("keydown", handleKeydown)
    return () => document.removeEventListener("keydown", handleKeydown)
  }, [])

  React.useEffect(() => {
    if (isOpen) {
      setTimeout(() => inputRef.current?.focus(), 50)
    } else {
      setQuery("")
      setResults([])
    }
  }, [isOpen])

  React.useEffect(() => {
    if (query.trim().length < 2) {
      setResults([])
      return
    }
    setSearching(true)
    const handle = setTimeout(async () => {
      try {
        const res = await fetch(`/api/search?q=${encodeURIComponent(query.trim())}`)
        const data = await res.json()
        setResults(data.results || [])
      } catch {
        setResults([])
      } finally {
        setSearching(false)
      }
    }, 250)
    return () => clearTimeout(handle)
  }, [query])

  const filteredNav = NAV_COMMANDS.filter((c) =>
    c.label.toLowerCase().includes(query.toLowerCase())
  )

  function go(href: string) {
    setIsOpen(false)
    router.push(href)
  }

  // Expõe globalmente pra topbar poder abrir a palette clicando na barra de busca
  React.useEffect(() => {
    ;(window as any).__openCommandPalette = () => setIsOpen(true)
  }, [])

  if (!isOpen) return null

  return (
    <div
      className="fixed inset-0 z-[120] flex items-start justify-center pt-[15vh] p-4 backdrop-blur-sm animate-in fade-in duration-150"
      style={{ background: "var(--modal-overlay)" }}
      onClick={() => setIsOpen(false)}
    >
      <div
        className="w-full max-w-xl rounded-xl shadow-2xl overflow-hidden animate-in zoom-in-95 slide-in-from-top-4 duration-200"
        style={{ background: "var(--modal-bg)", border: "1px solid var(--modal-border)" }}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center gap-3 px-4 py-3 border-b" style={{ borderColor: "var(--modal-border)" }}>
          {searching ? (
            <Loader2 className="h-4 w-4 animate-spin flex-shrink-0" style={{ color: "var(--text-tertiary)" }} />
          ) : (
            <Search className="h-4 w-4 flex-shrink-0" style={{ color: "var(--text-tertiary)" }} />
          )}
          <input
            ref={inputRef}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Buscar ativos, chamados, colaboradores... ou navegar"
            className="flex-1 bg-transparent outline-none text-sm"
            style={{ color: "var(--text-primary)" }}
          />
          <kbd className="hidden sm:inline text-[10px] px-1.5 py-0.5 rounded border" style={{ borderColor: "var(--border-primary)", color: "var(--text-tertiary)" }}>
            Esc
          </kbd>
        </div>

        <div className="max-h-[50vh] overflow-y-auto p-2">
          {query.trim().length >= 2 && results.length > 0 && (
            <div className="mb-2">
              <p className="px-2 py-1 text-[10px] uppercase font-bold tracking-wide" style={{ color: "var(--text-tertiary)" }}>
                Resultados
              </p>
              {results.map((r) => (
                <button
                  key={`${r.type}-${r.id}`}
                  onClick={() => go(r.href)}
                  className="w-full flex items-center justify-between gap-3 px-3 py-2.5 rounded-lg text-left transition-colors hover:bg-[var(--sidebar-item-hover)]"
                >
                  <div className="min-w-0">
                    <p className="text-sm font-medium truncate" style={{ color: "var(--text-primary)" }}>{r.label}</p>
                    <p className="text-xs truncate" style={{ color: "var(--text-tertiary)" }}>{r.sublabel}</p>
                  </div>
                  <span className="text-[10px] px-2 py-0.5 rounded-full flex-shrink-0" style={{ background: "var(--sidebar-item-active-bg)", color: "var(--text-tertiary)" }}>
                    {r.type}
                  </span>
                </button>
              ))}
            </div>
          )}

          {query.trim().length >= 2 && !searching && results.length === 0 && (
            <p className="px-3 py-6 text-sm text-center" style={{ color: "var(--text-tertiary)" }}>
              Nada encontrado pra "{query}"
            </p>
          )}

          <div>
            {filteredNav.length > 0 && (
              <p className="px-2 py-1 text-[10px] uppercase font-bold tracking-wide" style={{ color: "var(--text-tertiary)" }}>
                Navegação
              </p>
            )}
            {filteredNav.map((c) => (
              <button
                key={c.href}
                onClick={() => go(c.href)}
                className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-left transition-colors hover:bg-[var(--sidebar-item-hover)]"
              >
                <c.icon className="h-4 w-4 flex-shrink-0" style={{ color: "var(--text-tertiary)" }} />
                <span className="text-sm" style={{ color: "var(--text-primary)" }}>{c.label}</span>
              </button>
            ))}
          </div>
        </div>

        <div className="flex items-center gap-4 px-4 py-2 border-t text-[10px]" style={{ borderColor: "var(--modal-border)", color: "var(--text-tertiary)" }}>
          <span className="flex items-center gap-1"><CornerDownLeft className="h-3 w-3" /> selecionar</span>
          <span>Cmd/Ctrl + K pra abrir/fechar</span>
        </div>
      </div>
    </div>
  )
}

