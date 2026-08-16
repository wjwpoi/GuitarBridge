import path from "node:path";
import { fileURLToPath } from "node:url";

import { build } from "vite";

const hostRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const projectRoot = path.resolve(hostRoot, "..");

process.chdir(projectRoot);
await import("./stage-flutter.mjs");
await build({ configFile: path.join(hostRoot, "vite.config.ts") });
await import("./normalize-output.mjs");
