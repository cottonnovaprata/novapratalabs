import { PrismaClient } from "@prisma/client"

const prisma = new PrismaClient()

async function main() {
  await prisma.producer.upsert({
    where: { id: "producer-andre-diogo-dalben" },
    update: {},
    create: {
      id: "producer-andre-diogo-dalben",
      name: "André Diogo Dalben",
      status: "ativo",
      farms: {
        create: {
          name: "Fazenda principal",
          plots: {
            create: [
              { name: "01 e 02", areaHa: 145.4, variety: "FB 911" },
              { name: "03", areaHa: 55.6, variety: "FB 911" },
              { name: "04", areaHa: 10, variety: "FB 945" },
              { name: "04", areaHa: 20, variety: "FB 911" },
              { name: "06", areaHa: 90, variety: "FB 911" },
              { name: "08", areaHa: 74, variety: "DP 1949" },
            ],
          },
        },
      },
    },
  })

  await prisma.producer.upsert({
    where: { id: "producer-jose-olimpio-ascoli" },
    update: {},
    create: {
      id: "producer-jose-olimpio-ascoli",
      name: "José Olimpio Ascoli",
      status: "ativo",
      farms: {
        create: {
          name: "Fazenda principal",
          plots: {
            create: [
              { name: "1", areaHa: 25, variety: "TMG 84" },
              {
                name: "4",
                areaHa: 105,
                variety: "IMA 712 e SA 2271",
                splitArea: true,
                notes: "Área dividida entre as duas variedades",
              },
              { name: "5", areaHa: 45, variety: "Sem 2278 Dagma" },
              {
                name: "7",
                areaHa: 95,
                variety: "IMA 712 e 707",
                splitArea: true,
                notes: "Área dividida entre as duas variedades",
              },
            ],
          },
        },
      },
    },
  })

  await prisma.producer.upsert({
    where: { id: "producer-itacir-jose-picinin" },
    update: {},
    create: {
      id: "producer-itacir-jose-picinin",
      name: "Itacir José Picinin",
      status: "pendente",
      notes:
        "Recebido plantio de SOJA das fazendas Boa Vista e Celeste - falta confirmar dados de ALGODÃO 2026",
    },
  })

  await prisma.producer.upsert({
    where: { id: "producer-francisco-alberto-lermen" },
    update: {},
    create: {
      id: "producer-francisco-alberto-lermen",
      name: "Francisco Alberto Lermen",
      status: "pendente",
      notes: "Dados de plantio 2026 ainda não recebidos",
    },
  })

  console.log("Seed de produtores concluído")
}

main()
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
