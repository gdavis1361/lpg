# Tailwind Usage Enforcement

This project enforces a component-first approach to UI development, discouraging direct use of Tailwind CSS classes. This is especially important as we use Tailwind v4, which has syntax differences from v3 that LLMs may not be aware of.

## Guidelines for Using Tailwind v4

1. **Component-First Approach**
   - **DO** use pre-built components from shadcn/ui and Magic UI
   - **DO** create your own reusable components for common UI patterns
   - **DO NOT** use raw Tailwind classes in application code
   - **DO** keep Tailwind usage confined to component library files

2. **Example of Correct Usage:**
   ```tsx
   // GOOD: Using the component library
   import { Button, Card, Container } from '@/components/ui';
   
   function MyPage() {
     return (
       <Container>
         <Card>
           <h2>Hello World</h2>
           <p>This is a card with some content.</p>
           <Button>Click Me</Button>
         </Card>
       </Container>
     );
   }
   ```

3. **Example of Incorrect Usage:**
   ```tsx
   // BAD: Using raw Tailwind classes
   function MyPage() {
     return (
       <div className="max-w-7xl mx-auto px-4">
         <div className="bg-white rounded-lg shadow p-6">
           <h2 className="text-2xl font-bold">Hello World</h2>
           <p className="mt-2">This is a card with some content.</p>
           <button className="mt-4 px-4 py-2 bg-blue-500 text-white rounded">
             Click Me
           </button>
         </div>
       </div>
     );
   }
   ```

## Example Components

We've created example components to help you understand our approach:

1. **Component Library File**: `src/components/ui/ExampleComponents.tsx`
   - Shows how to create reusable components with Tailwind inside
   - These components handle the styling complexity so consumers don't have to

2. **Component Consumer File**: `src/components/ExampleConsumer.tsx`
   - Shows how to use our component library
   - No direct Tailwind classes - only component composition

## When Working with LLMs

When working with LLMs like Claude, give them specific instructions like:

```
Please use only imported components from shadcn/ui and Magic UI instead of raw Tailwind classes. 
Use our component library pattern. Do not generate HTML with direct className usage.
```

## Available Component Libraries

1. **shadcn/ui**: A collection of reusable components built with Radix UI and Tailwind
2. **Magic UI**: Custom UI components with advanced animations and effects

## Our Approach

By using a component-first approach, we:
- Ensure consistent styling across the application
- Avoid incompatibilities between Tailwind v3 and v4 syntax
- Make it easier for LLMs to generate correct code
- Improve maintainability and readability 