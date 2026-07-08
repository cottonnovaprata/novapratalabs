// Configuração de SLA por prioridade (em minutos).
// Cálculo é 24/7 corrido (sem considerar horário comercial/feriados) — ajustar aqui se precisar refinar.
export const SLA_CONFIG: Record<string, { response: number; resolution: number; label: string }> = {
  CRITICA: { response: 30, resolution: 4 * 60, label: "Crítica" },
  ALTA: { response: 2 * 60, resolution: 8 * 60, label: "Alta" },
  MEDIA: { response: 4 * 60, resolution: 24 * 60, label: "Média" },
  BAIXA: { response: 8 * 60, resolution: 72 * 60, label: "Baixa" },
}

export interface SlaTicketInput {
  priority: string
  status: string
  openedAt: string | Date
  closedAt?: string | Date | null
}

export interface SlaResult {
  deadline: Date
  isBreached: boolean
  isResolved: boolean
  minutesRemaining: number
  label: string
}

export function getSlaStatus(ticket: SlaTicketInput): SlaResult {
  const config = SLA_CONFIG[ticket.priority] || SLA_CONFIG.MEDIA
  const opened = new Date(ticket.openedAt)
  const deadline = new Date(opened.getTime() + config.resolution * 60000)
  const isResolved = ticket.status === "CONCLUIDO" && !!ticket.closedAt
  const reference = isResolved ? new Date(ticket.closedAt as string | Date) : new Date()
  const minutesRemaining = Math.round((deadline.getTime() - reference.getTime()) / 60000)
  const isBreached = minutesRemaining < 0

  let label: string
  if (isResolved) {
    label = isBreached ? "Resolvido fora do prazo" : "Resolvido dentro do prazo"
  } else if (isBreached) {
    label = `Atrasado há ${formatMinutes(Math.abs(minutesRemaining))}`
  } else {
    label = `${formatMinutes(minutesRemaining)} restantes`
  }

  return { deadline, isBreached, isResolved, minutesRemaining, label }
}

function formatMinutes(minutes: number): string {
  if (minutes < 60) return `${minutes}min`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}h`
  const days = Math.floor(hours / 24)
  return `${days}d`
}
