# NovaPrata Labs

Sistema interno de gestao de TI da Algodoeira Nova Prata / Cotton (Sorriso-MT).

Stack: Next.js 16 (App Router) + TypeScript + Prisma + PostgreSQL. Deploy no Vercel.

## Modulos ativos
- **Ativos** — inventario de equipamentos (CRUD + QR code de identificacao por ativo)
- **Colaboradores** — consulta de usuarios/responsaveis
- **Manutencoes** — historico de manutencao por ativo
- **Rede** — segmentos/VLANs cadastrados
- **Relatorios** — indicadores e exportacao (Excel/PDF)
- **Cofre** — credenciais sensiveis com log de acesso
- **Chamados** — suporte interno (categoria, prioridade, status, recorrencia, equipamento relacionado)
- **Certificados/Licencas** — controle de vencimento (certificado digital e licenca de software)
- **Fornecedores** — contatos de suporte e controle de contrato

## Pendencias conhecidas
- Rodar `npx prisma migrate dev` apos o pull para criar as tabelas `tickets`, `documents` e `suppliers` no banco.
- Dashboard (`/api/dashboard/stats`) ainda nao inclui os KPIs dos 3 modulos novos (chamados abertos, certificados vencendo, etc.) — proximo passo natural.

## Rodando localmente
```bash
npm install
cp .env.example .env   # configurar DATABASE_URL
npx prisma migrate dev
npm run dev
```
Acesse `http://localhost:3000`.

## Atencao
- Os dados de seed (`prisma/seed.ts`) sao ficticios (usuarios, setores e VLANs de exemplo) — nao refletem a rede real da empresa. Antes de usar em producao, revisar/substituir por dados reais (setores: escritorio, barracao, alojamento, gerencia).
- Consulte `STATUS_SISTEMA.md` para o estado atual detalhado do sistema.
- Consulte `DESIGN_SYSTEM.md` para os padroes visuais/tokens usados nos componentes.
- Consulte `QR_CODE_IMPLEMENTATION.md` para detalhes do QR code de ativos.
- `AGENTS.md`/`CLAUDE.md` contem instrucoes para agentes de IA (Claude Code) trabalharem neste repositorio.

## Deploy
Deploy automatico no Vercel a partir da branch principal. Ver `DEPLOYMENT.md`.
