// Rasterises SVG files with headless Chromium (Playwright).
// Usage: node tool/render_svg.mjs jobs.json
// jobs.json: [{"svg": "path.svg", "size": 192, "out": "path.png"}, ...]
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const jobs = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const browser = await chromium.launch();
const page = await browser.newPage({ deviceScaleFactor: 1 });
for (const job of jobs) {
  const data = Buffer.from(readFileSync(job.svg)).toString('base64');
  await page.setViewportSize({ width: job.size, height: job.size });
  await page.setContent(
    `<html><body style="margin:0;background:transparent">` +
      `<img src="data:image/svg+xml;base64,${data}" ` +
      `style="display:block;width:${job.size}px;height:${job.size}px"></body></html>`,
  );
  await page.waitForFunction(() => document.images[0].complete);
  await page.screenshot({ path: job.out, omitBackground: true });
}
await browser.close();
