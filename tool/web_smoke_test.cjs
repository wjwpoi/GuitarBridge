const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const { chromium } = require('playwright');

const root = path.resolve(process.argv[2] || 'build/web');
const prefix = '/GuitarBridge/';
const mime = { '.html': 'text/html', '.js': 'application/javascript', '.wasm': 'application/wasm', '.json': 'application/json', '.wav': 'audio/wav' };
const server = http.createServer((request, response) => {
  const url = new URL(request.url, 'http://localhost');
  if (!url.pathname.startsWith(prefix)) {
    response.writeHead(404).end();
    return;
  }
  const relative = decodeURIComponent(url.pathname.slice(prefix.length)) || 'index.html';
  const file = path.resolve(root, relative);
  if (!file.startsWith(root + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) {
    response.writeHead(404).end();
    return;
  }
  let content = fs.readFileSync(file);
  if (relative === 'index.html') {
    // Emulate deploying the release bundle with --base-href /GuitarBridge/.
    content = Buffer.from(content.toString().replace(/<base href="[^"]*">/, `<base href="${prefix}">`));
  }
  response.writeHead(200, { 'Content-Type': mime[path.extname(file)] || 'application/octet-stream' });
  response.end(content);
});

async function semantics(page) {
  const placeholder = page.locator('flt-semantics-placeholder');
  await placeholder.waitFor({ state: 'attached' });
  // This offscreen placeholder is activated by assistive technology, not a
  // pointer hit test. Enable semantics before using normal visible buttons.
  await placeholder.dispatchEvent('click');
  await page.getByRole('button', { name: '进入训练工作台', exact: true }).click();
  await page.getByRole('button', { name: '开始训练', exact: true }).waitFor();
}

async function scenario(browser, origin, missingWave) {
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 }, serviceWorkers: 'block' });
  const page = await context.newPage();
  page.setDefaultTimeout(60000);
  const errors = [];
  page.on('pageerror', (error) => errors.push(error.message));
  page.on('console', (message) => {
    if (message.type() === 'error') console.error('Browser:', message.text());
  });
  const requests = [];
  page.on('request', (request) => requests.push(request.url()));
  let releaseWasm;
  const wasmGate = new Promise((resolve) => { releaseWasm = resolve; });
  await page.route('**/libflutter_soloud_plugin.wasm', async (route) => {
    await wasmGate;
    await route.continue();
  });
  let failedWave = false;
  await page.route('**/*.wav', async (route) => {
    if (missingWave && !failedWave) {
      failedWave = true;
      await route.fulfill({ status: 404, body: 'missing sample' });
    } else {
      await route.continue();
    }
  });
  const wasmRequested = page.waitForRequest('**/libflutter_soloud_plugin.wasm');
  await page.goto(origin + prefix, { waitUntil: 'domcontentloaded' });
  await wasmRequested;
  assert.equal(requests.some((url) => url.endsWith('/flutter_bootstrap.js')), false,
    'Flutter must not boot before delayed WASM is ready');
  releaseWasm();
  await semantics(page);
  await page.evaluate(() => {
    const module = globalThis.Module_soloud;
    const play = module._play;
    globalThis.smokeCueCount = 0;
    module._play = (...args) => {
      globalThis.smokeCueCount++;
      return play(...args);
    };
  });
  await page.getByRole('button', { name: '开始训练', exact: true }).click();
  if (missingWave) {
    await page.getByText('声音没有可靠播放', { exact: true }).waitFor({ state: 'attached' });
    assert.equal(await page.getByText('找到目标音', { exact: true }).count(), 0);
    await page.getByRole('button', { name: '重试', exact: true }).click();
    await page.getByText('音频就绪', { exact: true }).waitFor({ state: 'attached' });
    await page.getByRole('button', { name: '重新尝试', exact: true }).click();
  }
  await page.getByText('找到目标音', { exact: true }).waitFor({ state: 'attached' });
  assert.ok(await page.evaluate(() => globalThis.smokeCueCount) >= 2,
    'Training must play both native cues, not merely render a state label');
  assert.ok(requests.some((url) => url.endsWith('.wav')));
  assert.deepEqual(errors, []);
  await context.close();
  console.log(missingWave ? 'PASS: missing WAV pauses training and retry recovers' : 'PASS: delayed WASM and subpath assets enter answer mode');
}

(async () => {
  let browser;
  try {
    await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
    const origin = `http://127.0.0.1:${server.address().port}`;
    browser = await chromium.launch({
      executablePath: process.env.CHROME_EXECUTABLE,
      headless: true,
      args: ['--autoplay-policy=no-user-gesture-required'],
    });
    await scenario(browser, origin, false);
    await scenario(browser, origin, true);
  } finally {
    if (browser) await browser.close();
    server.close();
  }
})().catch((error) => { console.error(error); process.exitCode = 1; });
