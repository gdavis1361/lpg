import React from "react";
import { Button } from "@/components/ui/button";
import { cva, type VariantProps } from "class-variance-authority";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";
import { Slot } from "@radix-ui/react-slot";
import { Loader2 } from "lucide-react";

const wowButtonVariants = cva(
  "relative inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 overflow-hidden",
  {
    variants: {
      variant: {
        default:
          "bg-primary text-primary-foreground shadow hover:bg-primary/90",
        destructive:
          "bg-destructive text-destructive-foreground shadow-sm hover:bg-destructive/90",
        outline:
          "border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground",
        secondary:
          "bg-secondary text-secondary-foreground shadow-sm hover:bg-secondary/80",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
        gradient: "bg-gradient-to-r from-navy to-gold text-white border-none shadow-md",
        bronze: "bg-bronze-600 text-white hover:bg-bronze-700",
        navy: "bg-navy-700 text-white hover:bg-navy-800",
        gold: "bg-gold-500 text-navy-900 hover:bg-gold-600",
      },
      size: {
        default: "h-9 px-4 py-2",
        sm: "h-8 rounded-md px-3 text-xs",
        lg: "h-10 rounded-md px-8",
        icon: "h-9 w-9",
      },
      glow: {
        default: "",
        true: "shadow-[0_0_15px_rgba(var(--primary-rgb)/0.5)]",
      },
      shimmer: {
        default: "",
        true: "before:absolute before:inset-0 before:-translate-x-full before:animate-[shimmer_2s_infinite] before:bg-gradient-to-r before:from-transparent before:via-white/20 before:to-transparent",
      },
      ripple: {
        default: "",
        true: "group", // We'll use group to apply ripple effect via JS
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
      glow: "default",
      shimmer: "default",
      ripple: "default",
    },
  }
);

export interface WowButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof wowButtonVariants> {
  asChild?: boolean;
  isLoading?: boolean;
  icon?: React.ReactNode;
  iconPosition?: "left" | "right";
  hoverScale?: number;
}

const WowButton = React.forwardRef<HTMLButtonElement, WowButtonProps>(
  (
    {
      className,
      variant,
      size,
      glow,
      shimmer,
      ripple,
      asChild = false,
      isLoading = false,
      icon,
      iconPosition = "left",
      hoverScale = 1.03,
      children,
      ...props
    },
    ref
  ) => {
    const Comp = asChild ? Slot : "button";
    const [rippleElements, setRippleElements] = React.useState<React.ReactNode[]>([]);
    
    // Ripple effect handler
    const handleRipple = ripple === true ? (event: React.MouseEvent<HTMLButtonElement>) => {
      const button = event.currentTarget;
      const rect = button.getBoundingClientRect();
      const x = event.clientX - rect.left;
      const y = event.clientY - rect.top;
      const size = Math.max(rect.width, rect.height) * 2;
      
      const rippleKey = Date.now();
      const ripple = (
        <motion.span
          key={rippleKey}
          className="absolute rounded-full bg-white/20 pointer-events-none"
          initial={{ width: 0, height: 0, x, y, opacity: 0.5 }}
          animate={{ width: size, height: size, x: x - size / 2, y: y - size / 2, opacity: 0 }}
          transition={{ duration: 0.6 }}
          onAnimationComplete={() => {
            setRippleElements(prev => prev.filter(item => (item as any).key !== rippleKey));
          }}
        />
      );
      
      setRippleElements(prev => [...prev, ripple]);
    } : undefined;
    
    const motionConfig = {
      whileHover: { scale: hoverScale },
      whileTap: { scale: 0.97 },
      transition: { type: "spring", stiffness: 500, damping: 30 }
    };
    
    return (
      <motion.div
        className="inline-block"
        {...motionConfig}
      >
        <Comp
          className={cn(wowButtonVariants({ variant, size, glow, shimmer, ripple, className }))}
          ref={ref}
          onClick={handleRipple}
          disabled={isLoading || props.disabled}
          {...props}
        >
          {isLoading && (
            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
          )}
          {!isLoading && icon && iconPosition === "left" && (
            <span className="mr-2">{icon}</span>
          )}
          {children}
          {!isLoading && icon && iconPosition === "right" && (
            <span className="ml-2">{icon}</span>
          )}
          {rippleElements}
        </Comp>
      </motion.div>
    );
  }
);

WowButton.displayName = "WowButton";

export { WowButton, wowButtonVariants }; 