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
    const [totalAssets, totalUsers, maintenanceCount, pendingActions, assetsByStatus, allTickets] = await Promise.all([
      prisma.asset.count(),
      prisma.user.count(),
      prisma.asset.count({ where: { status: "MANUTENCAO" } }),
      prisma.maintenance.count({
        where: {
          status: {
            in: ["PENDENTE", "EM_PROGRESSO"],
          },
        },
      }),
      prisma.asset.groupBy({
        by: ["status"],
        _count: { _all: true }
      }),
      prisma.ticket.findMany({
        select: { id: true, priority: true, status: true, category: true, openedAt: true, closedAt: true },
      }),
    ])

    const recentAssets = await prisma.asset.findMany({
      take: 5,
      orderBy: { createdAt: "desc" },
      include: { sector: true }
    })

    // --- SLA ---
    let slaBreached = 0
    let slaWithin = 0
    let resolvedCount = 0
    let resolvedMinutesSum = 0

    for (const t of allTickets) {
      const sla = getSlaStatus(t)
      if (sla.isBreached) slaBreached++
      else slaWithin++

      if (t.status === "CONCLUIDO" && t.closedAt) {
        resolvedCount++
        resolvedMinutesSum += (new Date(t.closedAt).getTime() - new Date(t.openedAt).getTime()) / 60000
      }
    }
    const avgResolutionMinutes = resolvedCount > 0 ? Math.round(resolvedMinutesSum / resolvedCount) : 0

    // --- Chamados abertos por dia (últimos 14 dias) ---
    const days: { date: string; abertos: number }[] = []
    const dayMap = new Map<string, number>()
    for (let i = 13; i >= 0; i--) {
      const d = new Date()
      d.setDate(d.getDate() - i)
      const key = d.toISOString().split("T")[0]
      dayMap.set(key, 0)
    }
    for (const t of allTickets) {
      const key = new Date(t.openedAt).toISOString().split("T")[0]
      if (dayMap.has(key)) dayMap.set(key, (dayMap.get(key) || 0) + 1)
    }
    for (const [date, abertos] of dayMap.entries()) {
      days.push({ date: date.slice(5), abertos })
    }

    // --- Chamados por categoria ---
    const categoryMap = new Map<string, number>()
    for (const t of allTickets) {
      categoryMap.set(t.category, (categoryMap.get(t.category) || 0) + 1)
    }
    const ticketsByCategory = Array.from(categoryMap.entries())
      .map(([category, count]) => ({ category, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 6)

    return NextResponse.json({
      totalAssets,
      totalUsers,
      maintenanceCount,
      alertsCount: pendingActions,
      assetsByStatus,
      recentAssets,
      sla: {
        openTickets: allTickets.filter((t: { status: string }) => t.status !== "CONCLUIDO").length,
        slaBreached,
        slaWithin,
        avgResolutionMinutes,
        ticketsByDay: days,
        ticketsByCategory,
      },
    })
  } catch (error) {
    console.error("Dashboard Stats Error:", error)
    return NextResponse.json({ error: "Erro ao carregar estatísticas" }, { status: 500 })
  }
}
