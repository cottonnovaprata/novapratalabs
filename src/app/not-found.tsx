import Link from "next/link"
import { Home, ArrowLeft } from "lucide-react"

export default function NotFound() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-background text-foreground">
      <div className="text-center space-y-6 max-w-md px-6">
        <div className="space-y-2">
          <p className="text-8xl font-bold text-muted-foreground/20">404</p>
          <h1 className="text-2xl font-bold tracking-tight">Página não encontrada</h1>
          <p className="text-muted-foreground text-sm">
            A página que você procura não existe ou foi movida.
          </p>
        </div>
        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <Link
            href="/dashboard"
            className="inline-flex items-center justify-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 transition-colors"
          >
            <Home className="h-4 w-4" />
            Ir para o Dashboard
          </Link>
          <Link
            href="javascript:history.back()"
            className="inline-flex items-center justify-center gap-2 rounded-md border border-input bg-background px-4 py-2 text-sm font-medium hover:bg-accent hover:text-accent-foreground transition-colors"
          >
            <ArrowLeft className="h-4 w-4" />
            Voltar
          </Link>
        </div>
      </div>
    </div>
  )
}
