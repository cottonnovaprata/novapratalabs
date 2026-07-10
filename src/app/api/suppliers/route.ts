import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function GET() {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const suppliers = await prisma.supplier.findMany({
      orderBy: { name: "asc" },
    })
    return NextResponse.json(suppliers)
  } catch (error) {
    console.error("Error fetching suppliers:", error)
    return NextResponse.json({ error: "Failed to fetch suppliers" }, { status: 500 })
  }
}

export async function POST(request: Request) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const body = await request.json()
    const { name, serviceType, contactName, phone, email, hasContract, contractEnd, notes } = body

    const supplier = await prisma.supplier.create({
      data: {
        name,
        serviceType,
        contactName: contactName || null,
        phone: phone || null,
        email: email || null,
        hasContract: !!hasContract,
        contractEnd: contractEnd ? new Date(contractEnd) : null,
        notes: notes || null,
      },
    })

    return NextResponse.json(supplier)
  } catch (error) {
    console.error("Error creating supplier:", error)
    if ((error as any).code === "P2002") {
      return NextResponse.json({ error: "Já existe um fornecedor com este nome" }, { status: 409 })
    }
    return NextResponse.json({ error: "Failed to create supplier" }, { status: 500 })
  }
}
