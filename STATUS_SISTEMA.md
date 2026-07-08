# STATUS DO SISTEMA - NOVAPRATA LABS

## 1) Estado geral (atual)
- Build de producao: OK (`npm run build` passou sem erros).
- App Router / paginas principais: carregam e compilam.
- Dashboard e Reports: com tratamento de falha transitoria (retry curto) para reduzir erro intermitente de banco.
- Tema: Light/Dark ativo via `ThemeProvider` e `data-theme`.

## 2) O que esta funcionando
### Autenticacao e sessao
- Login por `POST /api/auth/login`.
- Logout por `POST /api/auth/logout`.
- Rotas internas protegidas validam sessao na maioria dos endpoints de negocio.

### Modulos de negocio
- Ativos: listagem, criacao, detalhe/edicao/exclusao.
- Colaboradores: consulta.
- Manutencoes: listagem, criacao, consulta por ativo, atualizacao e exclusao.
- Rede: visao geral e criacao de segmentos.
- Relatorios: indicadores, exportacao e download.
- Cofre: listagem/criacao de credenciais e reveal por id.
- Chamados: listagem, criacao, atualizacao e exclusao (suporte interno com categoria/prioridade/status/recorrencia).
- Certificados/Licencas: listagem, criacao, atualizacao e exclusao, com calculo de dias para vencer.
- Fornecedores: listagem, criacao, atualizacao e exclusao, com controle de contrato.

### Dashboard / BI
- Cards de KPI com dados reais.
- Lista de ativos recentes.
- Grafico de distribuicao por status.
- Retry de carregamento para falha transitoria de API/banco.

## 3) UI/UX (premium)
### Tema e tokens visuais
- Tokens centralizados em `src/styles/theme-colors.css`.
- Variaveis para: backgrounds, textos, bordas, cards, inputs, botoes, status, sidebar, topbar e modal.
- Modo dark e light com contraste e hierarquia visual definidos.

### Componentes visuais
- Botao com variantes premium (`default`, `primary`, `secondary`, `outline`, `ghost`, etc.) em `src/components/ui/button.tsx`.
- Card com variantes (`default`, `elevated`, `outlined`, `filled`) em `src/components/ui/card.tsx`.
- Focus ring, hover/active e sombras consistentes.

### Layout Dashboard
- Sidebar recolhivel com estado ativo, hover e versao colapsada ajustada.
- Topbar com busca, toggle de tema, notificacao e bloco de usuario.
- Responsividade mantida em paginas do dashboard.

## 4) APIs / Endpoints mapeados
| Endpoint | Metodos | Sessao | Prisma/DB |
|---|---|---|---|
| `/api/assets` | GET, POST | Sim | Sim |
| `/api/assets/[id]` | GET, PUT, DELETE | Sim | Sim |
| `/api/auth/login` | POST | Nao | Sim |
| `/api/auth/logout` | POST | Nao | Nao |
| `/api/dashboard/stats` | GET | Sim | Sim |
| `/api/employees` | GET | Sim | Sim |
| `/api/maintenances` | GET, POST | Sim | Sim |
| `/api/maintenances/asset/[assetId]` | GET | Sim | Sim |
| `/api/maintenances/[id]` | PUT, DELETE | Sim | Sim |
| `/api/network/overview` | GET | Sim | Sim |
| `/api/network/segments` | POST | Sim | Sim |
| `/api/reports/download` | GET | Nao (fluxo proprio) | Nao |
| `/api/reports/export` | POST | Sim | Nao |
| `/api/reports/stats` | GET | Sim | Sim |
| `/api/sectors` | GET | Sim | Sim |
| `/api/vault/credentials` | GET, POST | Sim | Sim |
| `/api/vault/credentials/[id]/reveal` | POST | Sim | Sim |
| `/api/tickets` | GET, POST | Sim | Sim |
| `/api/tickets/[id]` | PUT, DELETE | Sim | Sim |
| `/api/documents` | GET, POST | Sim | Sim |
| `/api/documents/[id]` | PUT, DELETE | Sim | Sim |
| `/api/suppliers` | GET, POST | Sim | Sim |
| `/api/suppliers/[id]` | PUT, DELETE | Sim | Sim |

## 5) Pontos de atencao (sem quebra funcional)
- Pode ocorrer `503` transitorio quando o banco demora para responder (comum em ambiente local/cloud cold start).
- Com retry aplicado, a tela tende a recuperar automaticamente sem impacto no fluxo.
- Avisos de preload de fonte em `localhost` sao cosmeticos e nao bloqueiam uso.

## 6) Arquivos-chave de referencia
- `src/styles/theme-colors.css`
- `src/app/globals.css`
- `src/contexts/theme.tsx`
- `src/app/(dashboard)/layout-client.tsx`
- `src/app/(dashboard)/dashboard/page.tsx`
- `src/app/api/dashboard/stats/route.ts`
- `src/app/api/reports/stats/route.ts`
