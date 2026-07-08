import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const buttonVariants = cva(
  "inline-flex items-center justify-center whitespace-nowrap rounded-lg text-sm font-medium transition-all duration-200 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/50 disabled:pointer-events-none disabled:opacity-50 active:scale-95",
  {
    variants: {
      variant: {
        default:
          "bg-primary text-primary-foreground hover:brightness-110 active:brightness-95 shadow-sm shadow-primary/20",
        destructive:
          "bg-red-500/15 text-red-300 border border-red-500/25 hover:bg-red-500/25",
        outline:
          "border border-zinc-700/50 bg-background hover:bg-zinc-900/50 hover:border-zinc-600/50",
        secondary:
          "bg-zinc-700/30 text-zinc-200 border border-zinc-600/50 hover:bg-zinc-700/50",
        ghost: "hover:bg-zinc-900/40 hover:text-zinc-100 text-zinc-400",
        link: "text-primary hover:brightness-125 underline-offset-4 hover:underline",
      },
      size: {
        default: "h-9 px-4 py-2",
        sm: "h-8 rounded-lg px-3 text-xs",
        lg: "h-10 rounded-lg px-8",
        icon: "h-9 w-9",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button"
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = "Button"

export { Button, buttonVariants }

