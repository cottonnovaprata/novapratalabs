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
    const { name, serviceType, contactName, phone, email, hasContract, contractEnd, notes } = body

    const supplier = await prisma.supplier.update({
      where: { id },
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
    console.error("Error updating supplier:", error)
    if ((error as any).code === "P2002") {
      return NextResponse.json({ error: "Já existe um fornecedor com este nome" }, { status: 409 })
    }
    return NextResponse.json({ error: "Failed to update supplier" }, { status: 500 })
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
    await prisma.supplier.delete({ where: { id } })
    return NextResponse.json({ message: "Supplier deleted successfully" })
  } catch (error) {
    console.error("Error deleting supplier:", error)
    return NextResponse.json({ error: "Failed to delete supplier" }, { status: 500 })
  }
}
