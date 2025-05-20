/**
 * ESLint rule to detect direct usage of Tailwind classes
 * This prevents accidental Tailwind v3 vs v4 syntax mixing
 */

const TAILWIND_PATTERN = /^(bg|text|p|m|flex|grid|border|rounded|shadow|transition|transform|hover|focus|active|group|dark)[-:]|^(w-|h-|min-|max-|animate-|space-|gap-)/;

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'Disallow direct usage of Tailwind classes',
      category: 'Best Practices',
      recommended: true,
    },
    fixable: null,
    schema: [],
  },
  create(context) {
    return {
      JSXAttribute(node) {
        if (node.name.name === 'className') {
          const value = node.value;
          if (value && value.type === 'Literal' && typeof value.value === 'string') {
            const classes = value.value.split(/\s+/);
            for (const cls of classes) {
              if (TAILWIND_PATTERN.test(cls)) {
                context.report({
                  node,
                  message: 'Direct Tailwind class usage is not allowed. Use component library instead.',
                });
                break;
              }
            }
          }
        }
      },
    };
  },
}; 