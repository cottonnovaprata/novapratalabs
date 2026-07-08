"use client"

import React from "react"
import Link from "next/link"
import { usePathname, useRouter } from "next/navigation"
import { Monitor, LayoutDashboard, Box, Users, Lock, Network, PenTool, BarChart3, Settings, ChevronLeft, Search, Bell, LogOut, User, Ticket, FileText, Building2 } from "lucide-react"
import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import { ThemeToggle } from "@/components/theme-toggle"

const sidebarItems = [
  { icon: LayoutDashboard, label: "Dashboard", href: "/dashboard" },
  { icon: Box, label: "Ativos", href: "/assets" },
  { icon: Users, label: "Pessoas", href: "/employees" },
  { icon: Lock, label: "Cofre", href: "/vault" },
  { icon: Network, label: "Rede", href: "/network" },
  { icon: PenTool, label: "Manutenção", href: "/maintenances" },
  { icon: Ticket, label: "Chamados", href: "/tickets" },
  { icon: FileText, label: "Certificados/Licenças", href: "/documents" },
  { icon: Building2, label: "Fornecedores", href: "/suppliers" },
  { icon: BarChart3, label: "Relatórios", href: "/reports" },
]

export function DashboardLayoutClient({
  children,
}: {
  children: React.ReactNode
}) {
  const [isCollapsed, setIsCollapsed] = React.useState(false)
  const pathname = usePathname()
  const router = useRouter()

  async function handleLogout() {
    try {
      await fetch("/api/auth/logout", { method: "POST" })
    } finally {
      router.push("/login")
      router.refresh()
    }
  }

  return (
    <div className="flex min-h-screen" style={{ background: "var(--bg-primary)", color: "var(--text-primary)" }}>
      {/* Sidebar */}
      <aside
        className={cn(
          "fixed left-0 top-0 z-40 h-screen border-r transition-all duration-300 ease-in-out",
          isCollapsed ? "w-16" : "w-64"
        )}
        style={{ background: "var(--sidebar-bg)", borderColor: "var(--sidebar-border)" }}
      >
        <div className="flex h-14 items-center justify-between px-3 sm:px-4">
          <Link href="/dashboard" className="flex items-center gap-2 overflow-hidden py-2">
            <div className="min-w-[32px] bg-primary/90 p-1.5 rounded-lg hover:bg-primary transition-colors">
              <Monitor className="w-5 h-5 text-white" />
            </div>
            {!isCollapsed && (
              <span className="text-sm font-semibold tracking-tight whitespace-nowrap" style={{ color: "var(--text-primary)" }}>
                NovaPrata Labs
              </span>
            )}
          </Link>
          {!isCollapsed && (
            <Button
              variant="ghost"
              size="icon"
              className="h-7 w-7"
              onClick={() => setIsCollapsed(true)}
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
          )}
          {isCollapsed && (
            <Button
              variant="ghost"
              size="icon"
              className="absolute -right-3.5 top-14 h-7 w-7 rounded-full border"
              onClick={() => setIsCollapsed(false)}
              style={{ borderColor: "var(--border-primary)" }}
            >
              <ChevronLeft className={cn("h-4 w-4 transition-transform duration-200", isCollapsed && "rotate-180")} />
            </Button>
          )}
        </div>

        <nav className="mt-6 flex flex-col gap-1.5 px-2 sm:px-3">
          {sidebarItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex items-center gap-3 rounded-lg px-3 py-2.5 text-xs sm:text-sm font-medium transition-all duration-200 border",
                pathname === item.href
                  ? "text-[var(--sidebar-item-active-text)]"
                  : "text-zinc-600 hover:text-zinc-800 border-transparent"
              )}
              style={pathname === item.href ? {
                background: "var(--sidebar-item-active-bg)",
                borderColor: "var(--sidebar-item-active-border)",
                boxShadow: "var(--sidebar-item-active-shadow)",
              } : {
                background: "transparent",
                borderColor: "transparent"
              }}
              onMouseEnter={(e) => {
                if (pathname !== item.href) {
                  e.currentTarget.style.background = "var(--sidebar-item-hover)"
                }
              }}
              onMouseLeave={(e) => {
                if (pathname !== item.href) {
                  e.currentTarget.style.background = "transparent"
                }
              }}
            >
              <item.icon className={cn("h-4 w-4 sm:h-5 sm:w-5 min-w-[16px] sm:min-w-[20px] flex-shrink-0 transition-all", pathname === item.href ? "opacity-100" : "opacity-60")} />
              {!isCollapsed && <span className="whitespace-nowrap truncate">{item.label}</span>}
            </Link>
          ))}
        </nav>

        <div className="absolute bottom-4 left-0 w-full px-2 sm:px-3 space-y-1">
          <div className="mb-4 h-px mx-0.5" style={{ background: "var(--border-primary)" }} />
          <Link
            href="/settings"
            className={cn(
              "flex items-center gap-3 rounded-lg px-3 py-2.5 text-xs sm:text-sm font-medium transition-all duration-200"
            )}
            style={{ color: "var(--text-tertiary)" }}
            onMouseEnter={(e) => {
              e.currentTarget.style.background = "var(--sidebar-item-hover)"
              e.currentTarget.style.color = "var(--text-secondary)"
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.background = "transparent"
              e.currentTarget.style.color = "var(--text-tertiary)"
            }}
          >
            <Settings className="h-4 w-4 sm:h-5 sm:w-5 min-w-[16px] sm:min-w-[20px] flex-shrink-0" />
            {!isCollapsed && <span className="whitespace-nowrap">Configurações</span>}
          </Link>
          <button
            type="button"
            className={cn(
              "flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-left text-xs sm:text-sm font-medium transition-all duration-200"
            )}
            style={{ color: "var(--text-tertiary)" }}
            onClick={handleLogout}
            onMouseEnter={(e) => {
              e.currentTarget.style.background = "var(--status-error-bg)"
              e.currentTarget.style.color = "var(--status-error)"
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.background = "transparent"
              e.currentTarget.style.color = "var(--text-tertiary)"
            }}
          >
            <LogOut className="h-4 w-4 sm:h-5 sm:w-5 min-w-[16px] sm:min-w-[20px] flex-shrink-0" />
            {!isCollapsed && <span className="whitespace-nowrap">Sair</span>}
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main
        className={cn(
          "flex-1 transition-all duration-300",
          isCollapsed ? "pl-16" : "pl-64"
        )}
      >
        {/* Topbar */}
        <header className="sticky top-0 z-30 flex h-14 items-center justify-between border-b px-4 sm:px-6 gap-4" style={{ background: "var(--topbar-bg)", borderColor: "var(--topbar-border)" }}>
          <div className="relative w-full max-w-xs">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2" style={{ color: "var(--text-tertiary)" }} />
            <input
              type="text"
              placeholder="Buscar (Cmd + K)"
              className="h-9 w-full rounded-lg pl-9 pr-3 text-sm transition-all duration-200 focus:outline-none focus:ring-1 border"
              style={{
                background: "var(--input-bg)",
                borderColor: "var(--input-border)",
                color: "var(--input-text)",
              }}
              onFocus={(e) => {
                e.currentTarget.style.background = "var(--input-bg-focus)"
                e.currentTarget.style.borderColor = "var(--input-border-focus)"
              }}
              onBlur={(e) => {
                e.currentTarget.style.background = "var(--input-bg)"
                e.currentTarget.style.borderColor = "var(--input-border)"
              }}
            />
          </div>

          <div className="flex items-center gap-2 sm:gap-3 ml-auto">
            <ThemeToggle />
            <Button variant="ghost" size="icon" className="relative h-9 w-9 text-zinc-400 hover:text-zinc-200">
              <Bell className="h-4 w-4" />
              <span className="absolute right-2 top-2 flex h-1.5 w-1.5 rounded-full bg-red-500" />
            </Button>
            <div className="h-6 w-px hidden sm:block" style={{ background: "var(--border-primary)" }} />
            <div className="flex items-center gap-2 sm:gap-3">
              <div className="text-right hidden sm:flex flex-col gap-0.5">
                <p className="text-xs sm:text-sm font-medium" style={{ color: "var(--text-primary)" }}>Admin User</p>
                <p className="text-xs" style={{ color: "var(--text-tertiary)" }}>TI Manager</p>
              </div>
              <div className="h-8 w-8 rounded-lg flex items-center justify-center font-bold border flex-shrink-0" style={{ background: "rgba(37, 99, 235, 0.1)", borderColor: "rgba(37, 99, 235, 0.3)", color: "#2563eb" }}>
                <User className="h-4 w-4" />
              </div>
            </div>
          </div>
        </header>

        {/* Page Content */}
        <div className="p-4 sm:p-6 lg:p-8 min-h-screen" style={{ background: "var(--bg-primary)" }}>
          {children}
        </div>
      </main>
    </div>
  )
}
