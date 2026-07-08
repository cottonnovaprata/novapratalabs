import { NextResponse } from "next/server"
import bcrypt from "bcryptjs"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

export async function PUT(request: Request) {
  const session = await getSession()
  if (!session || typeof session.userId !== "string") {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const body = await request.json()
    const currentPassword = typeof body.currentPassword === "string" ? body.currentPassword : ""
    const newPassword = typeof body.newPassword === "string" ? body.newPassword : ""

    if (!currentPassword || !newPassword) {
      return NextResponse.json({ error: "Preencha a senha atual e a nova senha" }, { status: 400 })
    }
    if (newPassword.length < 6) {
      return NextResponse.json({ error: "A nova senha precisa ter pelo menos 6 caracteres" }, { status: 400 })
    }

    const user = await prisma.user.findUnique({ where: { id: session.userId } })
    if (!user) {
      return NextResponse.json({ error: "Usuário não encontrado" }, { status: 404 })
    }

    const isValid = await bcrypt.compare(currentPassword, user.password)
    if (!isValid) {
      return NextResponse.json({ error: "Senha atual incorreta" }, { status: 401 })
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10)
    await prisma.user.update({
      where: { id: user.id },
      data: { password: hashedPassword },
    })

    return NextResponse.json({ message: "Senha atualizada com sucesso" })
  } catch (error) {
    console.error("Change Password Error:", error)
    return NextResponse.json({ error: "Erro ao trocar senha" }, { status: 500 })
  }
}

