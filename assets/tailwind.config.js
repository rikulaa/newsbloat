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
    "../lib/**/views/*.ex",
    "../lib/**/live/**/*.ex",
    "../lib/**/live/**/*.leex"
  ],

  darkMode: false, // or 'media' or 'class'
  theme: {
    fontFamily: {
      sans: [
        'Montserrat',
        'Roboto',
        '"Helvetica Neue"',
        'Arial',
        '"Noto Sans"',
        'sans-serif',
        '"Apple Color Emoji"',
        '"Segoe UI Emoji"',
        '"Segoe UI Symbol"',
        '"Noto Color Emoji"',
      ],
      serif: [
        'Georgia',
        'Cambria',
        '"Times New Roman"',
        'Times',
        'serif',
      ],
      mono: [
        'Menlo',
        'Monaco',
        'Consolas',
        '"Liberation Mono"',
        '"Courier New"',
        'monospace',
      ],
    },
    extend: {
      colors: COLORS,
      zIndex: {
        '1': 1,
      }
    },
  },
  variants: {
    extend: {
      rotate: ['group-hover'],
    }
  },
  plugins: [
    function({ addUtilities, addComponents, e, prefix, config }) {
      // This function is your plugin
      const keys = ['all', 'opacity', 'background', 'background-color', 'color'];

      const transitions = keys.reduce((acc, key) => {
        acc[`.transition-${key}`] =  {
          transition: `${key} 0.2s`
        }
        return acc;
      }, {});

      const outlineColors = Object.keys(COLORS).reduce((acc, key) => {
        acc[`.shadow-outline-${key}`] = {
          'box-shadow': `0 0 0 2px ${COLORS[key]}`
        }
        return acc;
      }, {})

      addUtilities({...transitions, ...outlineColors}, ['responsive', 'hover', 'focus'])
    },
  ]
}
