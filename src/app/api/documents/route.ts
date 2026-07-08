import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function GET() {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const documents = await prisma.document.findMany({
      include: {
        responsible: { select: { name: true } },
        supplier: { select: { name: true } },
        asset: { select: { name: true, tag: true } },
      },
      orderBy: { validUntil: "asc" },
    })
    return NextResponse.json(documents)
  } catch (error) {
    console.error("Error fetching documents:", error)
    return NextResponse.json({ error: "Failed to fetch documents" }, { status: 500 })
  }
}

export async function POST(request: Request) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const body = await request.json()
    const { type, title, holder, validUntil, responsibleId, supplierId, assetId, notes } = body

    const document = await prisma.document.create({
      data: {
        type,
        title,
        holder,
        validUntil: new Date(validUntil),
        responsibleId: responsibleId || null,
        supplierId: supplierId || null,
        assetId: assetId || null,
        notes: notes || null,
      },
    })

    return NextResponse.json(document)
  } catch (error) {
    console.error("Error creating document:", error)
    return NextResponse.json({ error: "Failed to create document" }, { status: 500 })
  }
}
