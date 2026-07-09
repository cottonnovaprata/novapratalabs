import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  const andre = await prisma.produtor.upsert({
    where: { id: "produtor-andre-diogo-dalben" },
    update: {},
    create: {
      id: "produtor-andre-diogo-dalben",
      nome: "André Diogo Dalben",
      status: "ativo",
      fazendas: {
        create: {
          nome: "Fazenda principal",
          talhoes: {
            create: [
              { nome: "01 e 02", areaHa: 145.4, variedade: "FB 911" },
              { nome: "03", areaHa: 55.6, variedade: "FB 911" },
              { nome: "04", areaHa: 10, variedade: "FB 945" },
              { nome: "04", areaHa: 20, variedade: "FB 911" },
              { nome: "06", areaHa: 90, variedade: "FB 911" },
              { nome: "08", areaHa: 74, variedade: "DP 1949" },
            ],
          },
        },
      },
    },
  });

  const jose = await prisma.produtor.upsert({
    where: { id: "produtor-jose-olimpio-ascoli" },
    update: {},
    create: {
      id: "produtor-jose-olimpio-ascoli",
      nome: "José Olimpio Ascoli",
      status: "ativo",
      fazendas: {
        create: {
          nome: "Fazenda principal",
          talhoes: {
            create: [
              { nome: "1", areaHa: 25, variedade: "TMG 84" },
              {
                nome: "4",
                areaHa: 105,
                variedade: "IMA 712 e SA 2271",
                areaDividida: true,
                observacoes: "Área dividida entre as duas variedades",
              },
              { nome: "5", areaHa: 45, variedade: "Sem 2278 Dagma" },
              {
                nome: "7",
                areaHa: 95,
                variedade: "IMA 712 e 707",
                areaDividida: true,
                observacoes: "Área dividida entre as duas variedades",
              },
            ],
          },
        },
      },
    },
  });

  await prisma.produtor.upsert({
    where: { id: "produtor-itacir-jose-picinin" },
    update: {},
    create: {
      id: "produtor-itacir-jose-picinin",
      nome: "Itacir José Picinin",
      status: "pendente",
      observacoes:
        "Recebido plantio de SOJA das fazendas Boa Vista e Celeste - falta confirmar dados de ALGODÃO 2026",
    },
  });

  await prisma.produtor.upsert({
    where: { id: "produtor-francisco-alberto-lermen" },
    update: {},
    create: {
      id: "produtor-francisco-alberto-lermen",
      nome: "Francisco Alberto Lermen",
      status: "pendente",
      observacoes: "Dados de plantio 2026 ainda não recebidos",
    },
  });

  console.log("Seed concluído:", andre.nome, "/", jose.nome);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
