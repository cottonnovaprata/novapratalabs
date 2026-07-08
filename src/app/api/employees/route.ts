import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"
import bcrypt from "bcryptjs"
import crypto from "crypto"

export async function GET() {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        phone: true,
        department: true,
        jobTitle: true,
        status: true,
        _count: {
          select: { assets: true }
        }
      },
      orderBy: { name: "asc" }
    })
    return NextResponse.json(users)
  } catch (error) {
    return NextResponse.json({ error: "Erro ao buscar colaboradores" }, { status: 500 })
  }
}

export async function POST(request: Request) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Não autorizado" }, { status: 401 })
  }

  try {
    const body = await request.json()
    const { name, email, role, phone, department, jobTitle, status } = body

    if (!name || !email) {
      return NextResponse.json({ error: "Nome e e-mail são obrigatórios" }, { status: 400 })
    }

    // Senha temporária aleatória - o colaborador define a própria senha via "esqueci minha senha"
    const tempPassword = crypto.randomBytes(16).toString("hex")
    const hashedPassword = await bcrypt.hash(tempPassword, 10)

    const user = await prisma.user.create({
      data: {
        name,
        email,
        password: hashedPassword,
        role: role || "USER",
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
    console.error("Error creating employee:", error)
    return NextResponse.json({ error: "Erro ao criar colaborador" }, { status: 500 })
  }
}
