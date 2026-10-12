// Script ordering alone does not wait for asynchronous WASM initialization.
(() => {
  const createModule = globalThis.Module_soloud;
  let pending;
  globalThis.guitarBridgeEnsureAudioReady = () => {
    if (!pending) {
      pending = Promise.resolve()
        .then(() => createModule())
        .then((module) => {
          globalThis.Module_soloud = module;
          return module;
        })
        .catch((error) => {
          pending = undefined;
          throw error;
        });
    }
    return pending;
  };

  // Show the Flutter error/retry UI even if the module download fails. Its
  // audio backend uses the same function to retry initialization safely.
  globalThis.guitarBridgeEnsureAudioReady()
    .catch((error) => console.error('SoLoud WASM initialization failed:', error))
    .finally(() => {
      const script = document.createElement('script');
      script.src = 'flutter_bootstrap.js';
      document.body.appendChild(script);
    });
})();
