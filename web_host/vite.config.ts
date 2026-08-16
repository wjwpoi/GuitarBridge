import { sites } from "@openai/sites-vite-plugin";
import { defineConfig } from "vite";
import { fileURLToPath } from "node:url";

const hostRoot = fileURLToPath(new URL(".", import.meta.url));

export default defineConfig({
  root: hostRoot,
  publicDir: "public",
  build: {
    outDir: "../dist/client",
    emptyOutDir: true,
  },
  plugins: [sites()],
});
