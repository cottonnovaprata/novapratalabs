import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"
import { encryptVaultSecret } from "@/lib/vault-crypto"

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
    const body = (await request.json()) as {
      title?: string
      username?: string
      password?: string
      type?: string
      assetId?: string | null
    }

    const title = typeof body.title === "string" ? body.title.trim() : ""
    const username = typeof body.username === "string" ? body.username.trim() : ""
    const type = typeof body.type === "string" && body.type.trim() ? body.type.trim().toUpperCase() : "OTHER"
    const assetId = typeof body.assetId === "string" && body.assetId.trim() ? body.assetId.trim() : null
    const newPassword = typeof body.password === "string" ? body.password.trim() : ""

    if (!title || !username) {
      return NextResponse.json({ error: "Campos obrigatorios: title, username" }, { status: 400 })
    }

    const data: any = { title, username, type, assetId }

    // Só re-criptografa e marca rotação se uma nova senha foi de fato digitada
    if (newPassword) {
      data.passwordEncrypted = encryptVaultSecret(newPassword)
      data.lastRotatedAt = new Date()
    }

    const userId = typeof session.userId === "string" ? session.userId : null

    const updated = await prisma.$transaction(async (tx: any) => {
      const result = await tx.vaultCredential.update({ where: { id }, data })
      await tx.vaultAccessLog.create({
        data: {
          credentialId: id,
          userId,
          action: newPassword ? "ROTATE" : "UPDATE",
        },
      })
      return result
    })

    return NextResponse.json({
      id: updated.id,
      title: updated.title,
      username: updated.username,
      type: updated.type,
    })
  } catch (error: any) {
    if (error?.code === "P2002") {
      return NextResponse.json({ error: "Credencial com mesmo titulo e usuario ja existe" }, { status: 409 })
    }
    console.error("Vault Credential PUT Error:", error)
    return NextResponse.json({ error: "Erro ao atualizar credencial" }, { status: 500 })
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
    // Atencao: o log de acesso dessa credencial e apagado em cascata junto (onDelete: Cascade no schema).
    await prisma.vaultCredential.delete({ where: { id } })
    return NextResponse.json({ message: "Credencial removida com sucesso" })
  } catch (error) {
    console.error("Vault Credential DELETE Error:", error)
    return NextResponse.json({ error: "Erro ao excluir credencial" }, { status: 500 })
  }
}

