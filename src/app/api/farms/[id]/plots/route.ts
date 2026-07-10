import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function POST(
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

    if (!name || !areaHa || !variety) {
      return NextResponse.json({ error: "Talhão, área e variedade são obrigatórios" }, { status: 400 })
    }

    const plot = await prisma.plot.create({
      data: {
        name,
        areaHa: Number(areaHa),
        variety,
        splitArea: !!splitArea,
        notes: notes || null,
        season: season || "2026",
        farmId: id,
      },
    })

    return NextResponse.json(plot)
  } catch (error) {
    console.error("Error creating plot:", error)
    return NextResponse.json({ error: "Failed to create plot" }, { status: 500 })
  }
}
