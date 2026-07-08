import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"
import { encryptVaultSecret } from "@/lib/vault-crypto"

const ROTATION_LIMIT_DAYS = 90

function getRotationDeadlineDate() {
  return new Date(Date.now() - ROTATION_LIMIT_DAYS * 24 * 60 * 60 * 1000)
}

export async function GET() {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Nao autorizado" }, { status: 401 })
  }

  try {
    const deadline = getRotationDeadlineDate()
    const [credentials, staleCount, recentViews] = await Promise.all([
      prisma.vaultCredential.findMany({
        orderBy: [{ updatedAt: "desc" }],
        include: {
          asset: {
            select: {
              id: true,
              name: true,
              tag: true,
            },
          },
        },
      }),
      prisma.vaultCredential.count({
        where: {
          OR: [{ lastRotatedAt: null }, { lastRotatedAt: { lt: deadline } }],
        },
      }),
      prisma.vaultAccessLog.count({
        where: {
          createdAt: {
            gte: new Date(Date.now() - 24 * 60 * 60 * 1000),
          },
          action: {
            in: ["VIEW", "COPY"],
          },
        },
      }),
    ])

    return NextResponse.json({
      stats: {
        totalCredentials: credentials.length,
        staleCredentials: staleCount,
        recentViews,
        rotationLimitDays: ROTATION_LIMIT_DAYS,
      },
      credentials: credentials.map((credential: any) => ({
        id: credential.id,
        title: credential.title,
        username: credential.username,
        type: credential.type,
        assetId: credential.assetId,
        assetLabel: credential.asset?.tag || credential.asset?.name || "Sem ativo",
        lastUsedAt: credential.lastUsedAt,
        lastRotatedAt: credential.lastRotatedAt,
        isStale: !credential.lastRotatedAt || credential.lastRotatedAt < deadline,
      })),
    })
  } catch (error) {
    console.error("Vault Credentials GET Error:", error)
    return NextResponse.json({ error: "Erro ao carregar cofre" }, { status: 500 })
  }
}

export async function POST(request: Request) {
  const session = await getSession()
  if (!session) {
    return NextResponse.json({ error: "Nao autorizado" }, { status: 401 })
  }

  try {
    const body = (await request.json()) as {
      title?: string
      username?: string
      password?: string
      type?: string
      assetId?: string | null
    }

    const title = typeof body.title === "string" ? body.title.trim() : ""
    const username = typeof body.username === "string" ? body.username.trim() : ""
    const password = typeof body.password === "string" ? body.password : ""
    const type = typeof body.type === "string" && body.type.trim() ? body.type.trim().toUpperCase() : "OTHER"
    const assetId = typeof body.assetId === "string" && body.assetId.trim() ? body.assetId.trim() : null

    if (!title || !username || !password) {
      return NextResponse.json({ error: "Campos obrigatorios: title, username, password" }, { status: 400 })
    }

    const passwordEncrypted = encryptVaultSecret(password)

    const created = await prisma.vaultCredential.create({
      data: {
        title,
        username,
        passwordEncrypted,
        type,
        assetId,
        lastRotatedAt: new Date(),
      },
    })

    return NextResponse.json(
      {
        id: created.id,
        title: created.title,
        username: created.username,
        type: created.type,
      },
      { status: 201 }
    )
  } catch (error: unknown) {
    console.error("Vault Credentials POST Error:", error)
    if (
      typeof error === "object" &&
      error !== null &&
      "code" in error &&
      (error as { code?: string }).code === "P2002"
    ) {
      return NextResponse.json({ error: "Credencial com mesmo titulo e usuario ja existe" }, { status: 409 })
    }
    return NextResponse.json({ error: "Erro ao criar credencial" }, { status: 500 })
  }
}

