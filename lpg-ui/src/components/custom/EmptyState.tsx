import React from 'react';
import { Button } from '@/components/ui/button'; // Assuming shadcn/ui Button
import { cn } from '@/lib/utils'; // Assuming shadcn/ui utility

// Use React.ComponentProps for more accurate button prop typing
type ShadcnButtonProps = React.ComponentProps<typeof Button>;

interface EmptyStateProps {
  icon?: React.ReactNode;
  title: string;
  description?: string | React.ReactNode;
  action?: {
    text: string;
    onClick: () => void;
    buttonProps?: ShadcnButtonProps;
  };
  className?: string;
  iconClassName?: string;
  titleClassName?: string;
  descriptionClassName?: string;
}

export function EmptyState({
  icon,
  title,
  description,
  action,
  className,
  iconClassName,
  titleClassName,
  descriptionClassName,
}: EmptyStateProps) {
  return (
    <div
      className={cn(
        'flex flex-col items-center justify-center space-y-4 text-center p-8 rounded-lg border border-dashed border-muted-foreground/30 bg-card/50',
        className
      )}
    >
      {icon && <div className={cn('text-muted-foreground mb-4', iconClassName)}>{icon}</div>}
      
      <h3 className={cn('text-xl font-semibold text-foreground', titleClassName)}>
        {title}
      </h3>
      
      {description && (
        <p className={cn('text-sm text-muted-foreground', descriptionClassName)}>
          {description}
        </p>
      )}
      
      {action && (
        <Button onClick={action.onClick} {...action.buttonProps} className="mt-4">
          {action.text}
        </Button>
      )}
    </div>
  );
}
