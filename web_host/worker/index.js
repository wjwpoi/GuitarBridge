const immutableAsset = /\.(?:avif|css|gif|ico|jpeg|jpg|js|json|mp3|ogg|otf|png|svg|wasm|wav|webp|woff2)$/i;

function withWebHeaders(response, pathname) {
  const headers = new Headers(response.headers);
  headers.set("X-Content-Type-Options", "nosniff");
  headers.set("Referrer-Policy", "strict-origin-when-cross-origin");
  headers.set("Permissions-Policy", "camera=(), geolocation=(), microphone=()");
  if (immutableAsset.test(pathname) && !pathname.endsWith("manifest.json")) {
    headers.set("Cache-Control", "public, max-age=31536000, immutable");
  } else {
    headers.set("Cache-Control", "no-cache");
  }
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    let response = await env.ASSETS.fetch(request);

    if (
      response.status === 404 &&
      request.method === "GET" &&
      request.headers.get("Accept")?.includes("text/html")
    ) {
      response = await env.ASSETS.fetch(new Request(new URL("/", request.url), request));
    }

    if (response.headers.get("Content-Type")?.includes("text/html")) {
      const html = (await response.text()).replaceAll(
        "__GB_ORIGIN__",
        url.origin,
      );
      response = new Response(html, {
        status: response.status,
        statusText: response.statusText,
        headers: response.headers,
      });
    }

    return withWebHeaders(response, url.pathname);
  },
};
