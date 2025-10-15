import { defineConfig } from 'vite'

export default defineConfig({
  build: {
    outDir: '../web/assets',
    emptyOutDir: true,
    rollupOptions: {
      input: './src/input.css',
      output: {
        entryFileNames: 'input.css',
        assetFileNames: '[name][extname]',
      },
    },
  },
})
