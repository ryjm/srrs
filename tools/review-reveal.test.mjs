// The review page keeps a revealed back open across a swap only while the
// swap renders the same card at the same revision, so a grade key never
// answers a face the learner has not flipped. This runs the shell script
// embedded in desk/app/seer/index.hoon and the vendored htmx in headless
// Chromium, against pages shaped like +review-card and +grade-form.
// It skips when no Chromium is found; set CHROME_PATH to choose one.
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { delimiter, join } from "node:path";
import test from "node:test";
import { setTimeout as sleep } from "node:timers/promises";

const desk = new URL("../desk/", import.meta.url);
const index = (await readFile(new URL("app/seer/index.hoon", desk), "utf8")).split("\n");
const start = index.findIndex((line) => line.trim() === ";script:'''");
const end = index.findIndex((line, at) => at > start && line.trim() === "'''");
const shell = index.slice(start + 1, end).join("\n");
const htmx = await readFile(new URL("lib/web/htmx-min.js", desk), "utf8");

const ANSWER = "/apps/seer/actions/conditional-answer";
const CARD = "~nec|shared|card";
const reveal = (revision) => `reveal|${CARD}|${revision}`;

function page(revision) {
  const form = (grade) => `
    <form class="grade" method="post" action="${ANSWER}" hx-post="${ANSWER}"
      hx-target="#seer-app" hx-select="#seer-app" hx-swap="outerHTML show:top"
      hx-disabled-elt=".grade-row button" data-grade="${grade}">
      <input type="hidden" name="head-revision" value="${revision}">
      <input type="hidden" name="answer" value="${grade}">
      <button type="submit" class="grade-btn grade-${grade}">${grade}</button>
    </form>`;
  const review = revision === null
    ? `<section class="review-session" data-review="" data-remaining="0"></section>`
    : `<section class="review-session" data-review="" data-remaining="1">
        <div><article class="review-card" data-review-card="" tabindex="-1"
          data-key-item="review|${CARD}">
          <div class="review-prompt">front</div>
          <details class="flip" data-persist="${reveal(revision)}">
            <summary class="flip-bar">Show answer</summary>
            <div class="review-answer">back</div>
            <div class="grade-row">${["again", "hard", "good", "easy"].map(form).join("")}</div>
          </details>
        </article></div>
      </section>`;
  return `<!doctype html><html><head><script src="/htmx.js"></script>
    <script>${shell}</script></head>
    <body hx-boost="true" hx-target="#seer-app" hx-select="#seer-app"
      hx-swap="outerHTML show:top"><main id="seer-app">${review}</main></body></html>`;
}

// The ship: the review page shows .revision; each grade POST is logged and
// answered with the next of .answers, a [status, revision] pair.
async function ship(revision) {
  const state = { revision, answers: [], posts: [] };
  const server = createServer((req, res) => {
    let body = "";
    req.on("data", (chunk) => { body += chunk; });
    req.on("end", () => {
      if (req.url === "/htmx.js") {
        res.writeHead(200, { "content-type": "text/javascript" });
        res.end(htmx);
        return;
      }
      let status = 200;
      if (req.method === "POST" && req.url === ANSWER) {
        state.posts.push(new URLSearchParams(body).get("head-revision"));
        [status, state.revision] = state.answers.shift();
      }
      res.writeHead(status, { "content-type": "text/html" });
      res.end(page(state.revision));
    });
  });
  await new Promise((done) => server.listen(0, "127.0.0.1", done));
  state.url = `http://127.0.0.1:${server.address().port}/apps/seer/review`;
  state.close = () => new Promise((done) => {
    server.closeAllConnections();
    server.close(done);
  });
  return state;
}

function chromium() {
  if (process.env.CHROME_PATH) return process.env.CHROME_PATH;
  const names = ["chromium", "chromium-browser", "google-chrome", "google-chrome-stable"];
  for (const dir of (process.env.PATH ?? "").split(delimiter)) {
    for (const name of names) {
      if (dir && existsSync(join(dir, name))) return join(dir, name);
    }
  }
  return null;
}

// One headless tab, driven over the DevTools protocol. It only loads the
// local pages above, so it runs without the sandbox, which hosts that
// restrict user namespaces cannot provide.
async function tab(t, exe) {
  const profile = await mkdtemp(join(tmpdir(), "seer-reveal-"));
  const proc = spawn(exe, [
    "--headless=new", "--no-sandbox", "--remote-debugging-port=0", `--user-data-dir=${profile}`,
    "--no-first-run", "--no-default-browser-check", "--disable-gpu", "about:blank",
  ], { stdio: "ignore" });
  const exited = new Promise((done) => proc.once("exit", done));
  let socket = null;
  t.after(async () => {
    socket?.close();
    proc.kill();
    await exited;
    await rm(profile, { recursive: true, force: true, maxRetries: 10, retryDelay: 100 });
  });
  let port = null;
  for (let tries = 0; tries < 200 && !port; tries += 1) {
    port = await readFile(join(profile, "DevToolsActivePort"), "utf8")
      .then((text) => text.split("\n")[0], () => null);
    if (!port) await sleep(50);
  }
  assert.ok(port, "Chromium did not open a DevTools port");
  const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
  socket = new WebSocket(targets.find((target) => target.type === "page").webSocketDebuggerUrl);
  await new Promise((done, fail) => { socket.onopen = done; socket.onerror = fail; });
  const pending = new Map();
  let next = 0;
  socket.onmessage = ({ data }) => {
    const message = JSON.parse(data);
    const call = pending.get(message.id);
    if (!call) return;
    pending.delete(message.id);
    if (message.error) call.fail(new Error(message.error.message));
    else call.done(message.result);
  };
  const send = (method, params = {}) => new Promise((done, fail) => {
    next += 1;
    pending.set(next, { done, fail });
    socket.send(JSON.stringify({ id: next, method, params }));
  });
  const run = async (expression) => {
    const { result, exceptionDetails } = await send("Runtime.evaluate", {
      expression, awaitPromise: true, returnByValue: true,
    });
    if (exceptionDetails) throw new Error(exceptionDetails.text);
    return result.value;
  };
  return {
    run,
    async open(url) {
      await send("Page.navigate", { url });
      for (let tries = 0; tries < 200; tries += 1) {
        const ready = await run(
          "document.readyState === 'complete' && typeof htmx === 'object'",
        ).catch(() => false);
        if (ready) break;
        await sleep(25);
      }
      // count grade requests as htmx issues them, and swaps as they settle
      await run(`window.requests = 0; window.settled = 0;
        document.addEventListener("htmx:beforeRequest", () => { window.requests += 1; });
        document.addEventListener("htmx:afterSettle", () => { window.settled += 1; });
        true`);
    },
    async press(key) {
      const code = key === " " ? "Space" : `Digit${key}`;
      const keyCode = key.charCodeAt(0);
      await send("Input.dispatchKeyEvent", {
        type: "keyDown", key, code, text: key, windowsVirtualKeyCode: keyCode,
      });
      await send("Input.dispatchKeyEvent", {
        type: "keyUp", key, code, windowsVirtualKeyCode: keyCode,
      });
    },
    // run .act, then wait for the swap it starts to settle
    async swap(act) {
      const before = await run("window.settled");
      await act();
      for (let tries = 0; tries < 200; tries += 1) {
        if (await run("window.settled") > before) break;
        await sleep(25);
      }
      assert.ok(await run("window.settled") > before, "the swap did not settle");
      await run("new Promise((done) => requestAnimationFrame(() => done(true)))");
    },
    shown: () => run(`document.querySelector("[data-review] details.flip")
      ?.getAttribute("data-persist") ?? null`),
    revealed: () => run(`document.querySelector("[data-review] details.flip").open`),
    requests: () => run("window.requests"),
  };
}

test("a revision that comes back after a refused answer is closed", async (t) => {
  const exe = chromium();
  if (!exe) { t.skip("no Chromium found"); return; }
  const server = await ship("0v1");
  t.after(server.close);
  const browser = await tab(t, exe);
  await browser.open(server.url);
  assert.equal(await browser.shown(), reveal("0v1"));
  await browser.press("3");
  assert.equal(await browser.requests(), 0);
  // flip and grade; the ship refuses it and shows the card at 0v2
  await browser.press(" ");
  assert.equal(await browser.revealed(), true);
  server.answers.push([409, "0v2"]);
  await browser.swap(() => browser.press("3"));
  assert.equal(await browser.shown(), reveal("0v2"));
  assert.equal(await browser.revealed(), false);
  await browser.press("3");
  assert.equal(await browser.requests(), 1);
  // flip and grade again; a stack renamed and renamed back returns 0v1
  await browser.press(" ");
  server.answers.push([409, "0v1"]);
  await browser.swap(() => browser.press("3"));
  assert.equal(await browser.shown(), reveal("0v1"));
  assert.equal(await browser.revealed(), false);
  await browser.press("3");
  assert.equal(await browser.requests(), 2);
  // only a new flip grades it
  await browser.press(" ");
  server.answers.push([200, null]);
  await browser.swap(() => browser.press("3"));
  assert.equal(await browser.requests(), 3);
  assert.deepEqual(server.posts, ["0v1", "0v2", "0v1"]);
});

test("the same card at the same revision stays revealed across a refresh", async (t) => {
  const exe = chromium();
  if (!exe) { t.skip("no Chromium found"); return; }
  const server = await ship("0v1");
  t.after(server.close);
  const browser = await tab(t, exe);
  await browser.open(server.url);
  await browser.press(" ");
  await browser.swap(() => browser.run(`htmx.ajax("GET", "/apps/seer/review",
    { target: "#seer-app", select: "#seer-app", swap: "outerHTML" }).then(() => true)`));
  assert.equal(await browser.shown(), reveal("0v1"));
  assert.equal(await browser.revealed(), true);
  server.answers.push([200, null]);
  await browser.swap(() => browser.press("3"));
  assert.equal(await browser.requests(), 2);
  assert.deepEqual(server.posts, ["0v1"]);
});
