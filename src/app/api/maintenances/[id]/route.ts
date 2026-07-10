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
    const {
      problem,
      description,
      status,
      technician,
      cost,
      startDate,
      endDate
    } = body

    if (cost !== undefined && cost !== null && cost !== "" && parseFloat(cost) < 0) {
      return NextResponse.json({ error: "Custo não pode ser negativo" }, { status: 400 })
    }

    // 1. Fetch the maintenance record to get associated asset and previous status
    const maintenance = await prisma.maintenance.findUnique({
      where: { id },
      include: { asset: true }
    })

    if (!maintenance) {
      return NextResponse.json({ error: "Maintenance record not found" }, { status: 404 })
    }

    // 2. Perform updates in a transaction
    const result = await prisma.$transaction(async (tx) => {
      const updatedMaintenance = await tx.maintenance.update({
        where: { id },
        data: {
          problem,
          description,
          status,
          technician,
          cost: cost ? parseFloat(cost) : null,
          startDate: new Date(startDate),
          endDate: endDate ? new Date(endDate) : null,
        },
      })

      // 3. Logic: If status changed to CONCLUIDO or CANCELADO, restore asset status
      if (status === "CONCLUIDO" || status === "CANCELADO") {
        const restoreStatus = maintenance.previousAssetStatus || "EM_USO"
        await tx.asset.update({
          where: { id: maintenance.assetId },
          data: { status: restoreStatus },
        })
      }
      // 4. Logic: If status changed back to PENDENTE or EM_PROGRESSO, make sure asset is MANUTENCAO
      else if (status === "PENDENTE" || status === "EM_PROGRESSO") {
        await tx.asset.update({
          where: { id: maintenance.assetId },
          data: { status: "MANUTENCAO" },
        })
      }

      return updatedMaintenance
    })

    return NextResponse.json(result)
  } catch (error) {
    console.error("Error updating maintenance:", error)
    return NextResponse.json({ error: "Failed to update maintenance" }, { status: 500 })
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

    // Check if maintenance exists and what's its status
    const maintenance = await prisma.maintenance.findUnique({
      where: { id }
    })

    if (!maintenance) {
      return NextResponse.json({ error: "Maintenance record not found" }, { status: 404 })
    }

    // If deleting an active maintenance, maybe we should restore the asset status too?
    // User didn't specify, but it's safer to restore if it was in MANUTENCAO.
    await prisma.$transaction(async (tx) => {
      if (maintenance.status === "PENDENTE" || maintenance.status === "EM_PROGRESSO") {
        const restoreStatus = maintenance.previousAssetStatus || "EM_USO"
        await tx.asset.update({
          where: { id: maintenance.assetId },
          data: { status: restoreStatus },
        })
      }

      await tx.maintenance.delete({
        where: { id },
      })
    })

    return NextResponse.json({ message: "Maintenance deleted successfully" })
  } catch (error) {
    console.error("Error deleting maintenance:", error)
    return NextResponse.json({ error: "Failed to delete maintenance" }, { status: 500 })
  }
}
