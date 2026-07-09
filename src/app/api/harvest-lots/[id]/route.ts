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
    const { blockNumber, plot, harvestDate, classification, bales, totalWeightKg, status, invoiceNumber, notes } = body

    const lot = await prisma.harvestLot.update({
      where: { id },
      data: {
        blockNumber: blockNumber || null,
        plot: plot || null,
        harvestDate: harvestDate ? new Date(harvestDate) : null,
        classification: classification || null,
        bales: Number(bales) || 0,
        totalWeightKg: Number(totalWeightKg) || 0,
        status: status || "colhido",
        invoiceNumber: invoiceNumber || null,
        notes: notes || null,
      },
    })

    return NextResponse.json(lot)
  } catch (error) {
    console.error("Error updating harvest lot:", error)
    return NextResponse.json({ error: "Failed to update harvest lot" }, { status: 500 })
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
    await prisma.harvestLot.delete({ where: { id } })
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("Error deleting harvest lot:", error)
    return NextResponse.json({ error: "Failed to delete harvest lot" }, { status: 500 })
  }
}
