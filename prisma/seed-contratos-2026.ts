import { PrismaClient } from "@prisma/client"

const prisma = new PrismaClient()

async function main() {
  await prisma.producer.update({
    where: { id: "producer-andre-diogo-dalben" },
    data: {
      contractNumber: "003/2026",
      contractedAreaHa: 395,
      expectedBales: 3600,
      lotCount: 30,
      blockSequence: "101 A 200",
      hviLab: "COABRA",
      visualLab: "DS COTTON",
    },
  })

  await prisma.producer.update({
    where: { id: "producer-jose-olimpio-ascoli" },
    data: {
      contractNumber: "001/2026",
      contractedAreaHa: 158,
      expectedBales: 1400,
      lotCount: 10,
      blockSequence: "201 A 250",
      hviLab: "COABRA",
      visualLab: "DS COTTON",
      notes:
        "Área do contrato (158 ha) é a fonte oficial. A soma dos talhões cadastrados hoje dá 270 ha " +
        "(25+105+45+95) - conferir com o produtor se algum talhão mudou de safra ou se a divisão de área " +
        "entre variedades nos talhões 4 e 7 precisa ser revisada.",
    },
  })

  await prisma.producer.update({
    where: { id: "producer-itacir-jose-picinin" },
    data: {
      contractNumber: "004/2026",
      contractedAreaHa: 4040,
      expectedBales: 34806,
      lotCount: 249,
      blockSequence: "301 A 800",
      hviLab: "KULLMAN",
      visualLab: "COAMI",
      notes:
        "Área do contrato (4.040 ha) é a fonte oficial. A soma dos talhões cadastrados (fazendas Boa Vista " +
        "e Celeste) dá 4.069,2 ha - diferença de ~29 ha, provavelmente arredondamento ou pequeno ajuste " +
        "de área entre a planilha de plantio e o contrato fechado.",
    },
  })

  await prisma.producer.update({
    where: { id: "producer-francisco-alberto-lermen" },
    data: {
      status: "pendente",
      contractNumber: "002/2026",
      contractedAreaHa: 742,
      expectedBales: 6500,
      lotCount: 60,
      blockSequence: "001 A 100",
      hviLab: "COABRA",
      visualLab: "DS COTTON",
      notes: "Contrato e área confirmados (742 ha). Ainda falta o detalhamento de fazenda/talhão/variedade.",
    },
  })

  const otavio = await prisma.producer.upsert({
    where: { id: "producer-otavio-augusto-ascoli" },
    update: {},
    create: {
      id: "producer-otavio-augusto-ascoli",
      name: "Otávio Augusto Ascoli",
      status: "ativo",
      contractNumber: "001/2026",
      contractedAreaHa: 159,
      expectedBales: 1400,
      lotCount: 10,
      blockSequence: "251 A 300",
      hviLab: "COABRA",
      visualLab: "DS COTTON",
      notes:
        "Vinculado/família de José Olimpio Ascoli (mesmo sobrenome, contrato na mesma faixa 001/2026). " +
        "Já foi produtor na safra 2024/2025. Falta o detalhamento de fazenda/talhão/variedade da safra 2026.",
    },
  })

  console.log("Contratos 2026 atualizados. Novo produtor criado:", otavio.name)
}

main()
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
