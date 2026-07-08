import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function GET(request: Request) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  const { searchParams } = new URL(request.url)
  const status = searchParams.get("status")

  try {
    const tickets = await prisma.ticket.findMany({
      where: status ? { status: status as any } : {},
      include: {
        asset: { select: { name: true, tag: true } },
        responsible: { select: { name: true } },
      },
      orderBy: { openedAt: "desc" },
    })
    return NextResponse.json(tickets)
  } catch (error) {
    console.error("Error fetching tickets:", error)
    return NextResponse.json({ error: "Failed to fetch tickets" }, { status: 500 })
  }
}

export async function POST(request: Request) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const body = await request.json()
    const {
      requesterName,
      sector,
      category,
      description,
      priority,
      status,
      responsibleId,
      assetId,
      solution,
      recurring,
    } = body

    const ticket = await prisma.ticket.create({
      data: {
        requesterName,
        sector,
        category,
        description,
        priority: priority || "MEDIA",
        status: status || "ABERTO",
        responsibleId: responsibleId || null,
        assetId: assetId || null,
        solution: solution || null,
        recurring: !!recurring,
      },
    })

    return NextResponse.json(ticket)
  } catch (error) {
    console.error("Error creating ticket:", error)
    return NextResponse.json({ error: "Failed to create ticket" }, { status: 500 })
  }
}
