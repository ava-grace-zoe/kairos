{
  "extends": "./tsconfig.base.json",
  "compilerOptions": {
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "noEmit": true,
    "types": [
      "node"
    ]
  },
  "include": [
    "tests/**/*.ts",
    "vitest*.ts"
  ]
}
