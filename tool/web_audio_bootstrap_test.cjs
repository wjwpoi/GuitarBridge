const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');
const script = fs.readFileSync(path.join(__dirname, '../web/audio_bootstrap.js'), 'utf8');
const tick = () => new Promise((resolve) => setImmediate(resolve));

function bootstrap(factory) {
  const appended = [];
  const errors = [];
  const context = vm.createContext({
    Module_soloud: factory,
    console: { error: (...values) => errors.push(values) },
    document: {
      createElement: () => ({}),
      body: { appendChild: (node) => appended.push(node.src) },
    },
  });
  vm.runInContext(script, context);
  return { context, appended, errors };
}

test('Flutter waits for delayed WASM and concurrent requests share a Promise', async () => {
  let resolve;
  let calls = 0;
  const gate = new Promise((done) => { resolve = done; });
  const { context, appended } = bootstrap(() => { calls++; return gate; });
  const first = context.guitarBridgeEnsureAudioReady();
  assert.equal(first, context.guitarBridgeEnsureAudioReady());
  await tick();
  assert.equal(calls, 1);
  assert.deepEqual(appended, []);
  const module = { _isInited: () => 0 };
  resolve(module);
  await first;
  await tick();
  assert.equal(context.Module_soloud, module);
  assert.deepEqual(appended, ['flutter_bootstrap.js']);
  await context.guitarBridgeEnsureAudioReady();
  assert.equal(calls, 1);
});

test('failed WASM still launches error UI and can be retried', async () => {
  let calls = 0;
  const module = { _isInited: () => 0 };
  const { context, appended, errors } = bootstrap(() => {
    calls++;
    return calls === 1 ? Promise.reject(new Error('WASM missing')) : Promise.resolve(module);
  });
  await tick();
  assert.deepEqual(appended, ['flutter_bootstrap.js']);
  assert.equal(errors.length, 1);
  await context.guitarBridgeEnsureAudioReady();
  assert.equal(context.Module_soloud, module);
  assert.equal(calls, 2);
  assert.deepEqual(appended, ['flutter_bootstrap.js']);
});
