import assert from "node:assert/strict";
import { test } from "node:test";

import worker from "../cloudflare/worker.mjs";

const installerUrl =
  "https://raw.githubusercontent.com/testdogbot/ssh-toolbox/main/install.sh";

test("redirects HTTP to HTTPS before fetching installer", async () => {
  let fetchCalled = false;
  globalThis.fetch = async () => {
    fetchCalled = true;
    throw new Error("upstream fetch must not occur for HTTP");
  };

  const response = await worker.fetch(
    new Request("http://ssh-toolbox.alebot.ggff.net/"),
  );

  assert.equal(response.status, 301);
  assert.equal(
    response.headers.get("Location"),
    "https://ssh-toolbox.alebot.ggff.net/",
  );
  assert.equal(fetchCalled, false);
});

test("returns the current installer script at the HTTPS root", async () => {
  globalThis.fetch = async (url, options) => {
    assert.equal(url, installerUrl);
    assert.equal(options.method, "GET");
    return new Response("#!/bin/bash\necho ready\n");
  };

  const response = await worker.fetch(
    new Request("https://ssh-toolbox.alebot.ggff.net/"),
  );

  assert.equal(response.status, 200);
  assert.equal(
    response.headers.get("Content-Type"),
    "text/plain; charset=utf-8",
  );
  assert.equal(response.headers.get("Cache-Control"), "no-store");
  assert.match(await response.text(), /^#!\/bin\/bash/);
});

test("does not expose installer on unrelated paths or query URLs", async () => {
  const response = await worker.fetch(
    new Request("https://ssh-toolbox.alebot.ggff.net/other"),
  );
  const queryResponse = await worker.fetch(
    new Request("https://ssh-toolbox.alebot.ggff.net/?source=test"),
  );

  assert.equal(response.status, 404);
  assert.equal(queryResponse.status, 404);
});

test("rejects unsupported methods", async () => {
  const response = await worker.fetch(
    new Request("https://ssh-toolbox.alebot.ggff.net/", { method: "POST" }),
  );

  assert.equal(response.status, 405);
  assert.equal(response.headers.get("Allow"), "GET, HEAD");
});

test("reports upstream failures instead of returning a success-shaped body", async () => {
  globalThis.fetch = async () => new Response("unavailable", { status: 503 });

  const response = await worker.fetch(
    new Request("https://ssh-toolbox.alebot.ggff.net/"),
  );

  assert.equal(response.status, 502);
  assert.match(await response.text(), /Unable to fetch/);
});
