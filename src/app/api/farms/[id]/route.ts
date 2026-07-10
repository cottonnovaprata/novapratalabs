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
    const { name, producerId } = body

    const existing = await prisma.farm.findUnique({ where: { id } })
    if (!existing) {
      return NextResponse.json({ error: "Fazenda não encontrada" }, { status: 404 })
    }
    if (producerId && existing.producerId !== producerId) {
      return NextResponse.json({ error: "Fazenda não pertence a este produtor" }, { status: 403 })
    }

    const farm = await prisma.farm.update({
      where: { id },
      data: { name },
    })

    return NextResponse.json(farm)
  } catch (error) {
    console.error("Error updating farm:", error)
    return NextResponse.json({ error: "Failed to update farm" }, { status: 500 })
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
    const { searchParams } = new URL(request.url)
    const producerId = searchParams.get("producerId")

    const existing = await prisma.farm.findUnique({ where: { id } })
    if (!existing) {
      return NextResponse.json({ error: "Fazenda não encontrada" }, { status: 404 })
    }
    if (producerId && existing.producerId !== producerId) {
      return NextResponse.json({ error: "Fazenda não pertence a este produtor" }, { status: 403 })
    }

    await prisma.farm.delete({ where: { id } })
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("Error deleting farm:", error)
    return NextResponse.json({ error: "Failed to delete farm" }, { status: 500 })
  }
}
