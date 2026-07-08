import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const badgeVariants = cva(
  "inline-flex items-center rounded-md px-2.5 py-1 text-xs font-semibold transition-colors duration-200",
  {
    variants: {
      variant: {
        default:
          "dark:bg-primary/15 dark:text-[#a5b4fc] dark:border-primary/25 bg-indigo-50 text-indigo-700 border border-indigo-200",
        secondary:
          "dark:bg-zinc-500/10 dark:text-zinc-300 dark:border-zinc-500/20 bg-gray-50 text-gray-700 border border-gray-200",
        destructive:
          "dark:bg-red-500/15 dark:text-red-300 dark:border-red-500/25 bg-red-50 text-red-700 border border-red-200",
        outline: "dark:border-zinc-500/20 dark:bg-transparent dark:text-zinc-300 border border-gray-300 bg-transparent text-gray-700",
        success: "dark:bg-emerald-500/15 dark:text-emerald-300 dark:border-emerald-500/25 bg-emerald-50 text-emerald-700 border border-emerald-200",
        warning: "dark:bg-amber-500/15 dark:text-amber-300 dark:border-amber-500/25 bg-amber-50 text-amber-700 border border-amber-200",
        ghost: "dark:bg-zinc-900/40 dark:text-zinc-300 dark:border-zinc-700/20 bg-gray-50 text-gray-700 border border-gray-200",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
)

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return (
    <div className={cn(badgeVariants({ variant }), className)} {...props} />
  )
}

export { Badge, badgeVariants }

