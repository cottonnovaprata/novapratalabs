import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"
import { getSlaStatus } from "@/lib/sla"

export async function GET() {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const [openTickets, documents] = await Promise.all([
      prisma.ticket.findMany({
        where: { status: { not: "CONCLUIDO" } },
        select: { id: true, description: true, priority: true, status: true, openedAt: true, closedAt: true },
      }),
      prisma.document.findMany({
        select: { id: true, title: true, validUntil: true, type: true },
      }),
    ])

    const notifications: { id: string; type: "sla" | "document"; title: string; description: string; href: string; severity: "critical" | "warning" }[] = []

    for (const t of openTickets) {
      const sla = getSlaStatus(t)
      if (sla.isBreached) {
        notifications.push({
          id: `ticket-${t.id}`,
          type: "sla",
          title: "SLA estourado",
          description: t.description.slice(0, 70),
          href: "/tickets",
          severity: "critical",
        })
      }
    }

    const in15Days = new Date(Date.now() + 15 * 24 * 60 * 60 * 1000)
    for (const d of documents) {
      const validUntil = new Date(d.validUntil)
      if (validUntil < new Date()) {
        notifications.push({
          id: `doc-${d.id}`,
          type: "document",
          title: `${d.type === "CERTIFICADO" ? "Certificado" : "Licença"} vencido`,
          description: d.title,
          href: "/documents",
          severity: "critical",
        })
      } else if (validUntil <= in15Days) {
        notifications.push({
          id: `doc-${d.id}`,
          type: "document",
          title: `${d.type === "CERTIFICADO" ? "Certificado" : "Licença"} vencendo em breve`,
          description: d.title,
          href: "/documents",
          severity: "warning",
        })
      }
    }

    return NextResponse.json({ notifications, count: notifications.length })
  } catch (error) {
    console.error("Notifications Error:", error)
    return NextResponse.json({ error: "Erro ao carregar notificações" }, { status: 500 })
  }
}

