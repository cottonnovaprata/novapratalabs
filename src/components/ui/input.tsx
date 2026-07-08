import * as React from "react"
import { cn } from "@/lib/utils"

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          "flex h-9 w-full rounded-lg border px-3 py-2 text-sm transition-all duration-200 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-[var(--input-placeholder)] focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/50 disabled:cursor-not-allowed disabled:opacity-50",
          className
        )}
        style={{
          background: "var(--input-bg)",
          borderColor: "var(--input-border)",
          color: "var(--input-text)"
        }}
        onFocus={(e) => {
          e.currentTarget.style.background = "var(--input-bg-focus)"
          e.currentTarget.style.borderColor = "var(--input-border-focus)"
        }}
        onBlur={(e) => {
          e.currentTarget.style.background = "var(--input-bg)"
          e.currentTarget.style.borderColor = "var(--input-border)"
        }}
        ref={ref}
        {...props}
      />
    )
  }
)
Input.displayName = "Input"

export { Input }

