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
    const { name } = body

    if (!name) {
      return NextResponse.json({ error: "Nome da fazenda é obrigatório" }, { status: 400 })
    }

    const farm = await prisma.farm.create({
      data: { name, producerId: id },
    })

    return NextResponse.json(farm)
  } catch (error) {
    console.error("Error creating farm:", error)
    return NextResponse.json({ error: "Failed to create farm" }, { status: 500 })
  }
}
