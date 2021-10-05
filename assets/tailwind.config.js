const COLORS = {
  primary: "var(--color-primary)",
  secondary: "var(--color-secondary)",
  ancillary: "var(--color-ancillary)",
  foreground: "var(--color-foreground)",
  background: "var(--color-background)",
}

// tailwind.config.js
module.exports = {
  purge: [
    "../lib/**/*.eex",
    "../lib/**/*.leex",
    "../lib/**/*_view.ex",
    "../lib/**/views/*.ex"
  ],

  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {
      colors: COLORS
    },
  },
  variants: {},
  plugins: [],
}
