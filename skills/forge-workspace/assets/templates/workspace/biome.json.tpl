{
  "$schema": "https://biomejs.dev/schemas/2.5.14/schema.json",
  "vcs": {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
  },
  "files": {
    "includes": [
      "**",
      "!**/dist",
      "!**/node_modules",
      "!**/src/generated",
      "!**/coverage",
      "!**/.forge"
    ]
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single"
    },
    "parser": {
      "unsafeParameterDecoratorsEnabled": true
    }
  },
  "linter": {
    "enabled": true,
    "rules": {
      "preset": "recommended",
      "style": {
        "noNonNullAssertion": "off",
        "useImportType": "off"
      }
    }
  },
  "css": {
    "parser": {
      "tailwindDirectives": true
    },
    "formatter": {
      "enabled": true
    }
  },
  "json": {
    "formatter": {
      "expand": "always"
    }
  },
  "assist": {
    "actions": {
      "source": {
        "organizeImports": {
          "level": "on",
          "options": {
            "groups": [
              ":NODE:",
              "@__SCOPE__/**",
              ":PACKAGE:",
              ":PATH:"
            ]
          }
        }
      }
    }
  }
}
