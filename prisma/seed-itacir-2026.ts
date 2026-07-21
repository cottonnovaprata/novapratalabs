import { PrismaClient } from "@prisma/client"

const prisma = new PrismaClient()

async function main() {
  const itacir = await prisma.producer.update({
    where: { id: "producer-itacir-jose-picinin" },
    data: {
      status: "ativo",
      notes: "Plantio 2026 confirmado como algodão (fazendas Boa Vista e Celeste).",
      farms: {
        create: [
          {
            name: "Fazenda Boa Vista",
            plots: {
              create: [
                { name: "Th 1", areaHa: 300.94, variety: "TMG 33" },
                { name: "Th 3", areaHa: 174.88, variety: "TMG 44" },
                { name: "Th 3", areaHa: 50, variety: "TMG 33", splitArea: true, notes: "Área dividida com TMG 44 no mesmo talhão" },
                { name: "Th 4", areaHa: 223.22, variety: "TMG 44" },
                { name: "Th 5", areaHa: 236.85, variety: "FM 911" },
                { name: "Th 6", areaHa: 149.53, variety: "IMA 712", splitArea: true, notes: "Área dividida entre IMA 712, TMG 83, IMA 303 e FM 911" },
                { name: "Th 6", areaHa: 13.55, variety: "TMG 83", splitArea: true, notes: "Área dividida entre IMA 712, TMG 83, IMA 303 e FM 911" },
                { name: "Th 6", areaHa: 5.55, variety: "IMA 303", splitArea: true, notes: "Área dividida entre IMA 712, TMG 83, IMA 303 e FM 911" },
                { name: "Th 6", areaHa: 188.39, variety: "FM 911", splitArea: true, notes: "Área dividida entre IMA 712, TMG 83, IMA 303 e FM 911" },
                { name: "Th 7", areaHa: 185.12, variety: "TMG 44" },
                { name: "Th 8", areaHa: 29.49, variety: "TMG 44" },
                { name: "Th 9", areaHa: 101.13, variety: "TMG 44", splitArea: true, notes: "Área dividida com TMG 33 no mesmo talhão" },
                { name: "Th 9", areaHa: 28.33, variety: "TMG 33", splitArea: true, notes: "Área dividida com TMG 44 no mesmo talhão" },
                { name: "Th 10", areaHa: 138.52, variety: "TMG 44", splitArea: true, notes: "Área dividida com TMG 33 no mesmo talhão" },
                { name: "Th 10", areaHa: 15.33, variety: "TMG 33", splitArea: true, notes: "Área dividida com TMG 44 no mesmo talhão" },
                { name: "Th 11", areaHa: 156.41, variety: "TMG 33" },
              ],
            },
          },
          {
            name: "Fazenda Celeste",
            plots: {
              create: [
                { name: "Th 1", areaHa: 106.46, variety: "1949" },
                { name: "Th 2", areaHa: 235.82, variety: "1949", splitArea: true, notes: "Área dividida com IMA 712 no mesmo talhão" },
                { name: "Th 2", areaHa: 16.03, variety: "IMA 712", splitArea: true, notes: "Área dividida com 1949 no mesmo talhão" },
                { name: "Th 3", areaHa: 222.62, variety: "TMG 33" },
                { name: "Th 4", areaHa: 183.05, variety: "1949", splitArea: true, notes: "Área dividida entre 1949, 2356 APEX e BS 2324 GLITP" },
                { name: "Th 4", areaHa: 5.98, variety: "2356 APEX", splitArea: true, notes: "Área dividida entre 1949, 2356 APEX e BS 2324 GLITP" },
                { name: "Th 4", areaHa: 5.99, variety: "BS 2324 GLITP", splitArea: true, notes: "Área dividida entre 1949, 2356 APEX e BS 2324 GLITP" },
                { name: "Th 5", areaHa: 162.67, variety: "1949" },
                { name: "Th 6", areaHa: 148.91, variety: "1949", splitArea: true, notes: "Área dividida entre 1949, DY 1 ST e BS 2324 GLITP" },
                { name: "Th 6", areaHa: 7.3, variety: "DY 1 ST", splitArea: true, notes: "Área dividida entre 1949, DY 1 ST e BS 2324 GLITP" },
                { name: "Th 6", areaHa: 9.04, variety: "BS 2324 GLITP", splitArea: true, notes: "Área dividida entre 1949, DY 1 ST e BS 2324 GLITP" },
                { name: "Th 7", areaHa: 255.35, variety: "FM 911" },
                { name: "Th 8", areaHa: 23, variety: "TMG 44", splitArea: true, notes: "Área dividida com TMG 33 no mesmo talhão" },
                { name: "Th 8", areaHa: 30, variety: "TMG 33", splitArea: true, notes: "Área dividida com TMG 44 no mesmo talhão" },
                { name: "Th 9", areaHa: 290.71, variety: "TMG 33" },
                { name: "Th 10", areaHa: 308.66, variety: "1949" },
                { name: "Th 11", areaHa: 60.37, variety: "1949" },
              ],
            },
          },
        ],
      },
    },
  })

  console.log("Itacir atualizado com fazendas Boa Vista e Celeste:", itacir.name)
}

main()
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
