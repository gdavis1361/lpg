import React from 'react';

// Example component using shadcn UI for styling
export function Button({ 
  children, 
  variant = 'default',
  size = 'default',
  onClick,
  disabled = false,
}: {
  children: React.ReactNode;
  variant?: 'default' | 'destructive' | 'outline' | 'secondary' | 'ghost' | 'link';
  size?: 'default' | 'sm' | 'lg' | 'icon';
  onClick?: () => void;
  disabled?: boolean;
}) {
  // Internally, we use Tailwind, but consumers of this component don't need to
  const variantStyles = {
    default: 'bg-primary text-primary-foreground',
    destructive: 'bg-destructive text-destructive-foreground',
    outline: 'border border-input bg-background hover:bg-accent hover:text-accent-foreground',
    secondary: 'bg-secondary text-secondary-foreground',
    ghost: 'hover:bg-accent hover:text-accent-foreground',
    link: 'text-primary underline-offset-4 hover:underline',
  };

  const sizeStyles = {
    default: 'h-10 px-4 py-2',
    sm: 'h-9 rounded-md px-3',
    lg: 'h-11 rounded-md px-8',
    icon: 'h-10 w-10',
  };

  const baseStyles = 'inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50';

  return (
    <button
      className={`${baseStyles} ${variantStyles[variant]} ${sizeStyles[size]}`}
      onClick={onClick}
      disabled={disabled}
    >
      {children}
    </button>
  );
}

// Example component using Magic UI for styling
export function Card({ 
  children, 
  hoverEffect = false,
}: {
  children: React.ReactNode;
  hoverEffect?: boolean;
}) {
  // Internally, we use Tailwind, but consumers of this component don't need to
  const baseStyles = 'rounded-lg border p-4 bg-card text-card-foreground shadow-xs';
  const hoverStyles = hoverEffect ? 'transition-all duration-200 hover:shadow-md hover:-translate-y-1' : '';

  return (
    <div className={`${baseStyles} ${hoverStyles}`}>
      {children}
    </div>
  );
}

// Example layout component
export function Container({ 
  children,
  maxWidth = 'max-w-7xl',
  className = '',
}: {
  children: React.ReactNode;
  maxWidth?: string;
  className?: string;
}) {
  return (
    <div className={`mx-auto px-4 sm:px-6 lg:px-8 ${maxWidth} ${className}`}>
      {children}
    </div>
  );
}

// Example of how to use these components
export function ExamplePage() {
  return (
    <Container>
      <h1>Example Page</h1>
      <Card hoverEffect>
        <h2>Example Card</h2>
        <p>This is an example of how to use our component library.</p>
        <Button>Click Me</Button>
      </Card>
    </Container>
  );
}
