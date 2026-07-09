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
    const { name, areaHa, variety, splitArea, notes, season } = body

    const plot = await prisma.plot.update({
      where: { id },
      data: {
        name,
        areaHa: Number(areaHa),
        variety,
        splitArea: !!splitArea,
        notes: notes || null,
        season: season || "2026",
      },
    })

    return NextResponse.json(plot)
  } catch (error) {
    console.error("Error updating plot:", error)
    return NextResponse.json({ error: "Failed to update plot" }, { status: 500 })
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    await prisma.plot.delete({ where: { id } })
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("Error deleting plot:", error)
    return NextResponse.json({ error: "Failed to delete plot" }, { status: 500 })
  }
}
