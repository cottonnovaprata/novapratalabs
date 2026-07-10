import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    const producer = await prisma.producer.findUnique({
      where: { id },
      include: {
        farms: { include: { plots: true } },
        harvestLots: { orderBy: { createdAt: "desc" } },
        documents: { orderBy: { uploadedAt: "desc" }, select: { id: true, fileName: true, mimeType: true, fileSize: true, uploadedAt: true } },
      },
    })

    if (!producer) {
      return NextResponse.json({ error: "Produtor não encontrado" }, { status: 404 })
    }

    return NextResponse.json(producer)
  } catch (error) {
    console.error("Error fetching producer:", error)
    return NextResponse.json({ error: "Failed to fetch producer" }, { status: 500 })
  }
}

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
    const { name, document, stateRegistration, address, phone, email, whatsapp, status, notes } = body

    const producer = await prisma.producer.update({
      where: { id },
      data: {
        name,
        document: document || null,
        stateRegistration: stateRegistration || null,
        address: address || null,
        phone: phone || null,
        email: email || null,
        whatsapp: whatsapp || null,
        status: status || "ativo",
        notes: notes || null,
      },
    })

    return NextResponse.json(producer)
  } catch (error) {
    console.error("Error updating producer:", error)
    return NextResponse.json({ error: "Failed to update producer" }, { status: 500 })
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
    await prisma.producer.delete({ where: { id } })
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("Error deleting producer:", error)
    return NextResponse.json({ error: "Failed to delete producer" }, { status: 500 })
  }
}
