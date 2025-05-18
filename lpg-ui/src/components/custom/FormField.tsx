import React from 'react';
import { Controller, useFormContext, FieldError, ControllerRenderProps, FieldPath, FieldValues } from 'react-hook-form';
import { Label } from '@/components/ui/label'; 
import { cn } from '@/lib/utils'; 

interface FormFieldProps<TFieldValues extends FieldValues = FieldValues, TName extends FieldPath<TFieldValues> = FieldPath<TFieldValues>> {
  name: TName;
  label: string;
  children: React.ReactElement; 
  description?: string | React.ReactNode;
  className?: string;
  labelClassName?: string;
  inputContainerClassName?: string;
  errorClassName?: string;
  descriptionClassName?: string;
}

export function FormField<TFieldValues extends FieldValues = FieldValues, TName extends FieldPath<TFieldValues> = FieldPath<TFieldValues>>({
  name,
  label,
  children,
  description,
  className,
  labelClassName,
  inputContainerClassName,
  errorClassName,
  descriptionClassName,
}: FormFieldProps<TFieldValues, TName>) {
  const { control, formState: { errors } } = useFormContext<TFieldValues>();

  const error = errors[name] as FieldError | undefined;

  return (
    <div className={cn('space-y-2', className)}>
      <Label htmlFor={name} className={cn(error ? 'text-destructive' : '', labelClassName)}>
        {label}
      </Label>
      
      <div className={cn(inputContainerClassName)}>
        <Controller
          name={name}
          control={control}
          render={({ field }) => {
            // Destructure field to ensure all necessary props are handled
            const { ref, onChange, onBlur, value, disabled, name: fieldName } = field as ControllerRenderProps<TFieldValues, TName>;
            
            // Prepare the props for the child element
            const childProps = {
              ...(children.props || {}), // Ensure children.props is an object before spreading
              id: name, // Ensure id is set for label htmlFor
              'aria-invalid': !!error,
              // RHF controlled props
              name: fieldName,
              value: value,
              onChange: onChange,
              onBlur: onBlur,
              ref: ref,
              disabled: disabled,
            };
            
            return React.cloneElement(children, childProps);
          }}
        />
      </div>

      {description && !error && (
        <p className={cn('text-sm text-muted-foreground', descriptionClassName)}>
          {description}
        </p>
      )}

      {error && (
        <p className={cn('text-sm font-medium text-destructive', errorClassName)}>
          {error.message}
        </p>
      )}
    </div>
  );
}
