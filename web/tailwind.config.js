/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        warm: {
          50: '#FFF8F0',
          100: '#FFEED9',
          200: '#FFDDB3',
          300: '#FFC78A',
          400: '#FF9B6A',
          500: '#FF7A45',
          600: '#E85D2A',
          700: '#8B6F5C',
          800: '#6B5347',
          900: '#4A3728',
        }
      },
      fontFamily: {
        sans: ['"Noto Sans SC"', 'system-ui', '-apple-system', 'sans-serif'],
      }
    },
  },
  plugins: [],
}
