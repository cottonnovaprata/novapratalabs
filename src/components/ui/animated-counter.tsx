"use client"

import * as React from "react"
import { animate } from "framer-motion"

export function AnimatedCounter({ value, decimals = 0 }: { value: number; decimals?: number }) {
  const [display, setDisplay] = React.useState(0)
  const prevValue = React.useRef(0)

  React.useEffect(() => {
    const factor = 10 ** decimals
    const controls = animate(prevValue.current, value, {
      duration: 0.8,
      ease: "easeOut",
      onUpdate: (v) => setDisplay(Math.round(v * factor) / factor),
    })
    prevValue.current = value
    return () => controls.stop()
  }, [value, decimals])

  return <>{decimals > 0 ? display.toFixed(decimals) : display}</>
}
