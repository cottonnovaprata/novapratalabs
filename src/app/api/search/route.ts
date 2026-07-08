import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function GET(request: Request) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  const { searchParams } = new URL(request.url)
  const q = (searchParams.get("q") || "").trim()

  if (q.length < 2) {
    return NextResponse.json({ results: [] })
  }

  try {
    const insensitive = { contains: q, mode: "insensitive" as const }

    const [assets, tickets, employees, suppliers, documents] = await Promise.all([
      prisma.asset.findMany({
        where: { OR: [{ name: insensitive }, { tag: insensitive }] },
        select: { id: true, name: true, tag: true },
        take: 5,
      }),
      prisma.ticket.findMany({
        where: { OR: [{ description: insensitive }, { category: insensitive }] },
        select: { id: true, description: true, category: true, status: true },
        take: 5,
      }),
      prisma.user.findMany({
        where: { OR: [{ name: insensitive }, { email: insensitive }] },
        select: { id: true, name: true, email: true },
        take: 5,
      }),
      prisma.supplier.findMany({
        where: { name: insensitive },
        select: { id: true, name: true, serviceType: true },
        take: 5,
      }),
      prisma.document.findMany({
        where: { OR: [{ title: insensitive }, { holder: insensitive }] },
        select: { id: true, title: true, type: true },
        take: 5,
      }),
    ])

    const results = [
      ...assets.map((a: any) => ({ type: "Ativo", id: a.id, label: a.name, sublabel: a.tag, href: `/assets/${a.id}` })),
      ...tickets.map((t: any) => ({ type: "Chamado", id: t.id, label: t.description.slice(0, 60), sublabel: `${t.category} · ${t.status}`, href: `/tickets` })),
      ...employees.map((e: any) => ({ type: "Colaborador", id: e.id, label: e.name, sublabel: e.email, href: `/employees` })),
      ...suppliers.map((s: any) => ({ type: "Fornecedor", id: s.id, label: s.name, sublabel: s.serviceType, href: `/suppliers` })),
      ...documents.map((d: any) => ({ type: "Certificado/Licença", id: d.id, label: d.title, sublabel: d.holder, href: `/documents` })),
    ]

    return NextResponse.json({ results })
  } catch (error) {
    console.error("Global Search Error:", error)
    return NextResponse.json({ error: "Erro na busca" }, { status: 500 })
  }
}

