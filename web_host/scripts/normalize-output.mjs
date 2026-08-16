import { access, copyFile, mkdir, rename, rm } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const hostRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const projectRoot = path.resolve(hostRoot, "..");
const distRoot = path.join(projectRoot, "dist");
const rawClientRoot = path.join(distRoot, "client");
const rawAssets = path.join(rawClientRoot, "client");
const workerSource = path.join(hostRoot, "worker", "index.js");
const stagedAssets = path.join(distRoot, ".guitarbridge-client");
const serverDir = path.join(distRoot, "server");

await access(workerSource);
await rm(serverDir, { recursive: true, force: true });
await mkdir(serverDir, { recursive: true });
await copyFile(workerSource, path.join(serverDir, "index.js"));

try {
  await access(path.join(rawAssets, "flutter_bootstrap.js"));
  await rm(stagedAssets, { recursive: true, force: true });
  await rename(rawAssets, stagedAssets);
  await rm(rawClientRoot, { recursive: true, force: true });
  await rename(stagedAssets, rawClientRoot);
} catch {
  await access(path.join(rawClientRoot, "flutter_bootstrap.js"));
}
