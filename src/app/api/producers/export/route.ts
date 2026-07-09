import { NextResponse } from "next/server"
import ExcelJS from "exceljs"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export const runtime = "nodejs"
export const dynamic = "force-dynamic"

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

    const workbook = new ExcelJS.Workbook()

    const producersSheet = workbook.addWorksheet("Produtores")
    producersSheet.addRow([
      "Nome", "CPF/CNPJ", "Inscrição Estadual", "Status", "Telefone", "E-mail", "WhatsApp",
      "Área total (ha)", "Fazendas", "Talhões", "Fardos colhidos",
    ])
    for (const p of producers) {
      const areaTotal = p.farms.reduce((acc, f) => acc + f.plots.reduce((a, t) => a + t.areaHa, 0), 0)
      const totalPlots = p.farms.reduce((acc, f) => acc + f.plots.length, 0)
      const bales = p.harvestLots.reduce((acc, l) => acc + l.bales, 0)
      producersSheet.addRow([
        p.name, p.document || "", p.stateRegistration || "", p.status, p.phone || "", p.email || "", p.whatsapp || "",
        areaTotal, p.farms.length, totalPlots, bales,
      ])
    }
    producersSheet.getRow(1).font = { bold: true }
    producersSheet.columns.forEach((col) => { col.width = 22 })

    const plotsSheet = workbook.addWorksheet("Fazendas e Talhões")
    plotsSheet.addRow(["Produtor", "Fazenda", "Talhão", "Área (ha)", "Variedade", "Área dividida", "Safra"])
    for (const p of producers) {
      for (const f of p.farms) {
        for (const t of f.plots) {
          plotsSheet.addRow([p.name, f.name, t.name, t.areaHa, t.variety, t.splitArea ? "Sim" : "Não", t.season])
        }
      }
    }
    plotsSheet.getRow(1).font = { bold: true }
    plotsSheet.columns.forEach((col) => { col.width = 22 })

    const lotsSheet = workbook.addWorksheet("Colheita e Lotes")
    lotsSheet.addRow(["Produtor", "Bloco", "Talhão", "Data colheita", "Classificação", "Fardos", "Peso total (kg)", "Status", "Nota fiscal"])
    for (const p of producers) {
      for (const l of p.harvestLots) {
        lotsSheet.addRow([
          p.name, l.blockNumber || "", l.plot || "",
          l.harvestDate ? new Date(l.harvestDate).toLocaleDateString("pt-BR") : "",
          l.classification || "", l.bales, l.totalWeightKg, l.status, l.invoiceNumber || "",
        ])
      }
    }
    lotsSheet.getRow(1).font = { bold: true }
    lotsSheet.columns.forEach((col) => { col.width = 20 })

    const buffer = await workbook.xlsx.writeBuffer()
    const filename = `produtores-safra-2026-${new Date().toISOString().slice(0, 10)}.xlsx`

    return new NextResponse(new Uint8Array(buffer), {
      status: 200,
      headers: {
        "Content-Type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "Content-Disposition": `attachment; filename="${filename}"`,
        "Cache-Control": "no-store",
      },
    })
  } catch (error) {
    console.error("Error exporting producers:", error)
    return NextResponse.json({ error: "Failed to export producers" }, { status: 500 })
  }
}
