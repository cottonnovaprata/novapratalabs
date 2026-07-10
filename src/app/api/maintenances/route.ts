import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function GET(request: Request) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  const { searchParams } = new URL(request.url)
  const assetId = searchParams.get("assetId")

  try {
    const maintenances = await prisma.maintenance.findMany({
      where: assetId ? { assetId } : {},
      include: {
        asset: {
          select: {
            name: true,
            tag: true,
          },
        },
      },
      orderBy: {
        startDate: "desc",
      },
    })
    return NextResponse.json(maintenances)
  } catch (error) {
    console.error("Error fetching maintenances:", error)
    return NextResponse.json({ error: "Failed to fetch maintenances" }, { status: 500 })
  }
}

export async function POST(request: Request) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const body = await request.json()
    const { 
      assetId, 
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

    // 1. Fetch current asset status to save as previousAssetStatus
    const asset = await prisma.asset.findUnique({
      where: { id: assetId },
      select: { status: true }
    })

    if (!asset) {
      return NextResponse.json({ error: "Asset not found" }, { status: 404 })
    }

    // 2. Create maintenance and update asset status in a transaction
    const result = await prisma.$transaction(async (tx) => {
      const maintenance = await tx.maintenance.create({
        data: {
          assetId,
          problem,
          description,
          status,
          technician,
          cost: cost ? parseFloat(cost) : null,
          startDate: new Date(startDate),
          endDate: endDate ? new Date(endDate) : null,
          previousAssetStatus: asset.status,
        },
      })

      // Update asset status to MANUTENCAO
      await tx.asset.update({
        where: { id: assetId },
        data: { status: "MANUTENCAO" },
      })

      return maintenance
    })

    return NextResponse.json(result)
  } catch (error) {
    console.error("Error creating maintenance:", error)
    return NextResponse.json({ error: "Failed to create maintenance" }, { status: 500 })
  }
}
