/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  safelist: [
    // Animations
    'animate-spring-in',
    'animate-slide-up',
    'animate-shimmer',
    'gradient-animate',
    'gradient-mesh-animate',
    // Micro-interactions
    'btn-ripple',
    'btn-shine',
    'transition-smooth',
    // Glassmorphism
    'glass-premium',
    'glass-dark',
    'glass-layer-1',
    'glass-layer-2',
    'glass-layer-3',
    // Gradients
    'mesh-gradient',
    // Stagger
    'stagger-1',
    'stagger-2',
    'stagger-3',
    'stagger-4',
    // Page transitions
    'page-enter',
    'page-enter-active'
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
