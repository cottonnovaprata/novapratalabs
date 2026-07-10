"use client"

import * as React from "react"
import { animate } from "framer-motion"

export function AnimatedCounter({ value }: { value: number }) {
  const [display, setDisplay] = React.useState(0)
  const prevValue = React.useRef(0)

  React.useEffect(() => {
    const controls = animate(prevValue.current, value, {
      duration: 0.8,
      ease: "easeOut",
      onUpdate: (v) => setDisplay(Math.round(v)),
    })
    prevValue.current = value
    return () => controls.stop()
  }, [value])

  return <>{display}</>
}
