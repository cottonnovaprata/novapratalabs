import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function GET() {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const producers = await prisma.producer.findMany({
      include: {
        farms: { include: { plots: true } },
        harvestLots: true,
      },
      orderBy: { name: "asc" },
    })
    return NextResponse.json(producers)
  } catch (error) {
    console.error("Error fetching producers:", error)
    return NextResponse.json({ error: "Failed to fetch producers" }, { status: 500 })
  }
}

export async function POST(request: Request) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const body = await request.json()
    const { name, document, stateRegistration, address, phone, email, whatsapp, status, notes } = body

    if (!name) {
      return NextResponse.json({ error: "Nome é obrigatório" }, { status: 400 })
    }

    const duplicate = await prisma.producer.findFirst({
      where: { name: { equals: name.trim(), mode: "insensitive" } },
    })
    if (duplicate) {
      return NextResponse.json({ error: `Já existe um produtor cadastrado como "${duplicate.name}"` }, { status: 409 })
    }

    const producer = await prisma.producer.create({
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
    console.error("Error creating producer:", error)
    return NextResponse.json({ error: "Failed to create producer" }, { status: 500 })
  }
}
