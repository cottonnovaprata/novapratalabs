import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

function isValidIpv4(ip: string) {
  const parts = ip.split(".")
  if (parts.length !== 4) return false
  return parts.every((part) => {
    const n = Number(part)
    return !Number.isNaN(n) && n >= 0 && n <= 255
  })
}

function isValidCidr(cidr: string) {
  const [ip, bitsRaw] = cidr.split("/")
  const bits = Number(bitsRaw)
  return isValidIpv4(ip) && Number.isInteger(bits) && bits >= 8 && bits <= 30
}

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Nao autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    const body = await request.json()
    const name = typeof body.name === "string" ? body.name.trim() : ""
    const gateway = typeof body.gateway === "string" ? body.gateway.trim() : ""
    const vlan = typeof body.vlan === "string" ? body.vlan.trim() : ""
    const cidr = typeof body.cidr === "string" ? body.cidr.trim() : ""
    const totalIps = Number.isInteger(body.totalIps) && body.totalIps > 0 ? body.totalIps : 254
    const status = typeof body.status === "string" && body.status.trim() ? body.status.trim().toUpperCase() : "ONLINE"
    const notes = typeof body.notes === "string" && body.notes.trim().length > 0 ? body.notes.trim() : null

    if (!name || !gateway || !vlan || !cidr) {
      return NextResponse.json({ error: "Campos obrigatorios: name, gateway, vlan, cidr" }, { status: 400 })
    }
    if (!isValidIpv4(gateway)) {
      return NextResponse.json({ error: "Gateway invalido" }, { status: 400 })
    }
    if (!isValidCidr(cidr)) {
      return NextResponse.json({ error: "CIDR invalido. Exemplo: 10.0.10.0/24" }, { status: 400 })
    }

    const updated = await prisma.networkSegment.update({
      where: { id },
      data: { name, gateway, vlan, cidr, totalIps, status, notes },
    })

    return NextResponse.json(updated)
  } catch (error: any) {
    if (error?.code === "P2002") {
      return NextResponse.json({ error: "VLAN ou CIDR ja cadastrado" }, { status: 409 })
    }
    console.error("Update Network Segment Error:", error)
    return NextResponse.json({ error: "Erro ao atualizar segmento de rede" }, { status: 500 })
  }
}

export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Nao autorizado" }, { status: 401 })
  }

  try {
    const { id } = await params
    await prisma.networkSegment.delete({ where: { id } })
    return NextResponse.json({ message: "Segmento removido com sucesso" })
  } catch (error) {
    console.error("Delete Network Segment Error:", error)
    return NextResponse.json({ error: "Erro ao excluir segmento de rede" }, { status: 500 })
  }
}

