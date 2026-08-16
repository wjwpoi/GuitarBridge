import worker from "../worker/index.js";

const env = {
  ASSETS: {
    fetch: async () =>
      new Response(
        '<meta property="og:image" content="__GB_ORIGIN__/og.png">',
        { headers: { "Content-Type": "text/html" } },
      ),
  },
};

const response = await worker.fetch(
  new Request("https://guitarbridge.example/"),
  env,
);
const html = await response.text();

if (!html.includes("https://guitarbridge.example/og.png")) {
  throw new Error("The worker did not expand the social image origin.");
}
if (response.headers.get("X-Content-Type-Options") !== "nosniff") {
  throw new Error("The worker did not attach its security headers.");
}

console.log("Web host worker smoke test passed.");
