{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  config: {
    // Serve the engine's fallback font (Roboto) from this site instead of
    // fonts.gstatic.com, which is unreachable on some networks (notably
    // mainland China). Chinese UI text uses the bundled Noto fonts.
    fontFallbackBaseUrl: "fonts/",
  },
});
