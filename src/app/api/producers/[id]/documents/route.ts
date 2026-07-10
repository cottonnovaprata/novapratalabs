import { NextResponse } from "next/server"
import prisma from "@/lib/prisma"
import { getSession } from "@/lib/auth"

const MAX_FILE_SIZE_BYTES = 4 * 1024 * 1024 // 4MB (limite prático do body em serverless functions)

export async function POST(
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
    const { fileName, mimeType, fileData } = body

    if (!fileName || !mimeType || !fileData) {
      return NextResponse.json({ error: "Arquivo inválido" }, { status: 400 })
    }

    const sizeBytes = Math.ceil((fileData.length * 3) / 4)
    if (sizeBytes > MAX_FILE_SIZE_BYTES) {
      return NextResponse.json({ error: "Arquivo maior que 4MB não é suportado" }, { status: 413 })
    }

    const producer = await prisma.producer.findUnique({ where: { id } })
    if (!producer) {
      return NextResponse.json({ error: "Produtor não encontrado" }, { status: 404 })
    }

    const doc = await prisma.producerDocument.create({
      data: {
        producerId: id,
        fileName,
        mimeType,
        fileSize: sizeBytes,
        fileData,
      },
      select: { id: true, fileName: true, mimeType: true, fileSize: true, uploadedAt: true },
    })

    return NextResponse.json(doc)
  } catch (error) {
    console.error("Error uploading document:", error)
    return NextResponse.json({ error: "Failed to upload document" }, { status: 500 })
  }
}
