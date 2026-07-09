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
    const { blockNumber, plot, harvestDate, classification, bales, totalWeightKg, status, invoiceNumber, notes, season } = body

    const lot = await prisma.harvestLot.create({
      data: {
        blockNumber: blockNumber || null,
        producerId: id,
        plot: plot || null,
        harvestDate: harvestDate ? new Date(harvestDate) : null,
        classification: classification || null,
        bales: Number(bales) || 0,
        totalWeightKg: Number(totalWeightKg) || 0,
        status: status || "colhido",
        invoiceNumber: invoiceNumber || null,
        notes: notes || null,
        season: season || "2026",
      },
    })

    return NextResponse.json(lot)
  } catch (error) {
    console.error("Error creating harvest lot:", error)
    return NextResponse.json({ error: "Failed to create harvest lot" }, { status: 500 })
  }
}
