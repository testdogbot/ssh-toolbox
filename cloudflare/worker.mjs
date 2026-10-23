const INSTALL_SCRIPT_URL =
  "https://raw.githubusercontent.com/testdogbot/ssh-toolbox/main/install.sh";

export default {
  async fetch(request) {
    const requestUrl = new URL(request.url);

    if (requestUrl.protocol === "http:") {
      requestUrl.protocol = "https:";
      return Response.redirect(requestUrl.toString(), 301);
    }

    if (requestUrl.pathname !== "/" || requestUrl.search) {
      return new Response("Not found\n", { status: 404 });
    }

    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Method not allowed\n", {
        status: 405,
        headers: { Allow: "GET, HEAD" },
      });
    }

    const upstream = await fetch(INSTALL_SCRIPT_URL, {
      method: request.method,
      headers: { "User-Agent": "ssh-toolbox-short-link" },
    });

    if (!upstream.ok) {
      return new Response("Unable to fetch the SSH Toolbox installer\n", {
        status: 502,
        headers: { "Cache-Control": "no-store" },
      });
    }

    return new Response(upstream.body, {
      status: 200,
      headers: {
        "Cache-Control": "no-store",
        "Content-Type": "text/plain; charset=utf-8",
        "X-Content-Type-Options": "nosniff",
      },
    });
  },
};
