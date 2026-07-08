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
    const { name, email, role, phone, department, jobTitle, status } = body

    const user = await prisma.user.update({
      where: { id },
      data: {
        name,
        email,
        role,
        phone: phone || null,
        department: department || null,
        jobTitle: jobTitle || null,
        status: status || "ATIVO",
      },
    })

    return NextResponse.json({ ...user, password: undefined })
  } catch (error: any) {
    if (error?.code === "P2002") {
      return NextResponse.json({ error: "Já existe um colaborador com esse e-mail" }, { status: 409 })
    }
    console.error("Error updating employee:", error)
    return NextResponse.json({ error: "Erro ao atualizar colaborador" }, { status: 500 })
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

    const assetsCount = await prisma.asset.count({ where: { userId: id } })
    if (assetsCount > 0) {
      return NextResponse.json(
        { error: `Este colaborador tem ${assetsCount} ativo(s) vinculado(s). Reatribua os ativos antes de excluir.` },
        { status: 409 }
      )
    }

    await prisma.user.delete({ where: { id } })
    return NextResponse.json({ message: "Colaborador removido com sucesso" })
  } catch (error) {
    console.error("Error deleting employee:", error)
    return NextResponse.json({ error: "Erro ao excluir colaborador" }, { status: 500 })
  }
}
