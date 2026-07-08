import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
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

    const ticket = await prisma.ticket.update({
      where: { id },
      data: {
        requesterName,
        sector,
        category,
        description,
        priority,
        status,
        responsibleId: responsibleId || null,
        assetId: assetId || null,
        solution: solution || null,
        recurring: !!recurring,
        closedAt: status === "CONCLUIDO" ? new Date() : null,
      },
    })

    return NextResponse.json(ticket)
  } catch (error) {
    console.error("Error updating ticket:", error)
    return NextResponse.json({ error: "Failed to update ticket" }, { status: 500 })
  }
}

export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    await prisma.ticket.delete({ where: { id } })
    return NextResponse.json({ message: "Ticket deleted successfully" })
  } catch (error) {
    console.error("Error deleting ticket:", error)
    return NextResponse.json({ error: "Failed to delete ticket" }, { status: 500 })
  }
}
