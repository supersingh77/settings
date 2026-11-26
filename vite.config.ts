import tailwindcss from "@tailwindcss/vite"
import react from "@vitejs/plugin-react"
import { defineConfig } from "vite"

export default defineConfig({
  root: "web",
  plugins: [react(), tailwindcss()],
  server: {
    allowedHosts: true,
    hmr: false,
    proxy: {
      "/api": "http://127.0.0.1:4173",
      "/health": "http://127.0.0.1:4173",
    },
  },
  build: {
    outDir: "../dist/web",
    emptyOutDir: true,
  },
})
