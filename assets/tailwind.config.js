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
    extend: {},
  },
  variants: {},
  plugins: [],
}
