import { access, cp, copyFile, mkdir, rm } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const hostRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const projectRoot = path.resolve(hostRoot, "..");
const flutterBuild = path.join(projectRoot, "build", "web");
const publicDir = path.join(hostRoot, "public");
const viteIndex = path.join(hostRoot, "index.html");
const hostMetadataDir = path.join(hostRoot, ".openai");

await access(path.join(flutterBuild, "flutter_bootstrap.js"));
await access(path.join(flutterBuild, "assets", "packages", "flutter_soloud", "web", "libflutter_soloud_plugin.wasm"));

await rm(publicDir, { recursive: true, force: true });
await mkdir(publicDir, { recursive: true });
await cp(flutterBuild, publicDir, { recursive: true });
await copyFile(path.join(flutterBuild, "index.html"), viteIndex);
await mkdir(hostMetadataDir, { recursive: true });
await copyFile(
  path.join(projectRoot, ".openai", "hosting.json"),
  path.join(hostMetadataDir, "hosting.json"),
);
