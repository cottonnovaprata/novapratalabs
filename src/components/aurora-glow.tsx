"use client"

// Elemento de assinatura visual do NovaPrata Labs: um brilho ambiente sutil,
// nas cores da marca (indigo) + sinal ao vivo (ciano), evocando um pulso de
// monitoramento — combina com o produto (SLA, rede, uptime).
// Respeita prefers-reduced-motion.
export function AuroraGlow() {
  return (
    <div
      aria-hidden
      className="pointer-events-none absolute inset-x-0 top-0 -z-10 h-[420px] overflow-hidden"
    >
      <div
        className="absolute -top-40 left-[8%] h-[420px] w-[420px] rounded-full opacity-[0.16] blur-[110px] motion-safe:animate-[aurora-pulse_9s_ease-in-out_infinite]"
        style={{ background: "radial-gradient(circle, var(--primary) 0%, transparent 70%)" }}
      />
      <div
        className="absolute -top-32 right-[10%] h-[360px] w-[360px] rounded-full opacity-[0.12] blur-[110px] motion-safe:animate-[aurora-pulse_11s_ease-in-out_infinite_1.5s]"
        style={{ background: "radial-gradient(circle, var(--signal) 0%, transparent 70%)" }}
      />
    </div>
  )
}

