// The review page keeps a revealed back open across a render only while
// the render shows the same card at the same revision, so a grade key never
// answers a face the learner has not flipped. A page htmx puts back from its
// history cache is a render too. This runs the shell script embedded in
// desk/app/seer/index.hoon and the vendored htmx in headless Chromium,
// against pages shaped like +review-card and +grade-form.
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
const HOME = "/apps/seer";
const REVIEW = "/apps/seer/review";
const INBOX = "/apps/seer/inbox";
const CARD = "~nec|shared|card";
const reveal = (revision) => `reveal|${CARD}|${revision}`;

function review(revision) {
  const form = (grade) => `
    <form class="grade" method="post" action="${ANSWER}" hx-post="${ANSWER}"
      hx-target="#seer-app" hx-select="#seer-app" hx-swap="outerHTML show:top"
      hx-disabled-elt=".grade-row button" data-grade="${grade}">
      <input type="hidden" name="head-revision" value="${revision}">
      <input type="hidden" name="answer" value="${grade}">
      <button type="submit" class="grade-btn grade-${grade}">${grade}</button>
    </form>`;
  return revision === null
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
}

// The review is at /apps/seer and /apps/seer/review; the inbox has no card.
function page(path, revision) {
  return `<!doctype html><html><head><script src="/htmx.js"></script>
    <script>${shell}</script></head>
    <body hx-boost="true" hx-target="#seer-app" hx-select="#seer-app"
      hx-swap="outerHTML show:top"><main id="seer-app">
      <nav><a href="${REVIEW}">Review</a> <a href="${INBOX}">Inbox</a></nav>
      ${path === INBOX ? "<section>Inbox</section>" : review(revision)}
    </main></body></html>`;
}

// The ship: the review shows .revision; each grade POST is logged and
// answered with the next of .answers, a [status, revision] pair, and pushes
// the review URL, as +render-action-page does.
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
      const headers = { "content-type": "text/html" };
      let status = 200;
      if (req.method === "POST" && req.url === ANSWER) {
        state.posts.push(new URLSearchParams(body).get("head-revision"));
        [status, state.revision] = state.answers.shift();
        headers["hx-push-url"] = REVIEW;
      }
      res.writeHead(status, headers);
      res.end(page(req.url, state.revision));
    });
  });
  await new Promise((done) => server.listen(0, "127.0.0.1", done));
  state.origin = `http://127.0.0.1:${server.address().port}`;
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
  const frame = () => run("new Promise((done) => requestAnimationFrame(() => done(true)))");
  // wait until the page's counter .name passes .before
  const until = async (name, before, message) => {
    for (let tries = 0; tries < 200; tries += 1) {
      if (await run(`window.${name}`) > before) break;
      await sleep(25);
    }
    assert.ok(await run(`window.${name}`) > before, message);
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
      // count grade requests as htmx issues them, swaps as they settle,
      // toggles as the page sees them, and pages put back from history,
      // keeping the markup history had cached
      await run(`window.grades = 0; window.settled = 0; window.toggled = 0;
        window.restored = 0;
        document.addEventListener("htmx:beforeRequest", (e) => {
          if (e.detail.elt.hasAttribute("data-grade")) window.grades += 1;
        });
        document.addEventListener("htmx:afterSettle", () => { window.settled += 1; });
        document.addEventListener("toggle", () => { window.toggled += 1; }, true);
        document.addEventListener("htmx:historyRestore", (e) => {
          window.restored += 1;
          window.cached = e.detail.item ? e.detail.item.content : null;
        });
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
      await until("settled", before, "the swap did not settle");
      await frame();
    },
    // open the back with space. the browser sends the toggle event the
    // page keeps the reveal by as a later task, so wait for it, as a
    // learner's next key would
    async flip() {
      const before = await run("window.toggled");
      await this.press(" ");
      await until("toggled", before, "the back did not open");
    },
    // click a link; htmx boosts it and pushes its URL
    follow(href) {
      return this.swap(() => run(`document.querySelector('a[href="${href}"]').click(); true`));
    },
    // render the review again, with a GET that leaves history alone
    refresh() {
      return this.swap(() => run(`htmx.ajax("GET", "${REVIEW}",
        { target: "#seer-app", select: "#seer-app", swap: "outerHTML" }).then(() => true)`));
    },
    // go back a page, and wait for htmx to put it back
    async back() {
      const before = await run("window.restored");
      await run("history.back(); true");
      await until("restored", before, "the page was not put back");
      await frame();
    },
    shown: () => run(`document.querySelector("[data-review] details.flip")
      ?.getAttribute("data-persist") ?? null`),
    revealed: () => run(`document.querySelector("[data-review] details.flip").open`),
    grades: () => run("window.grades"),
    cached: () => run("window.cached"),
  };
}

test("a revision that comes back after a refused answer is closed", async (t) => {
  const exe = chromium();
  if (!exe) { t.skip("no Chromium found"); return; }
  const server = await ship("0v1");
  t.after(server.close);
  const browser = await tab(t, exe);
  await browser.open(`${server.origin}${REVIEW}`);
  assert.equal(await browser.shown(), reveal("0v1"));
  await browser.press("3");
  assert.equal(await browser.grades(), 0);
  // flip and grade; the ship refuses it and shows the card at 0v2
  await browser.flip();
  assert.equal(await browser.revealed(), true);
  server.answers.push([409, "0v2"]);
  await browser.swap(() => browser.press("3"));
  assert.equal(await browser.shown(), reveal("0v2"));
  assert.equal(await browser.revealed(), false);
  await browser.press("3");
  assert.equal(await browser.grades(), 1);
  // flip and grade again; a stack renamed and renamed back returns 0v1
  await browser.flip();
  server.answers.push([409, "0v1"]);
  await browser.swap(() => browser.press("3"));
  assert.equal(await browser.shown(), reveal("0v1"));
  assert.equal(await browser.revealed(), false);
  await browser.press("3");
  assert.equal(await browser.grades(), 2);
  // only a new flip grades it
  await browser.flip();
  server.answers.push([200, null]);
  await browser.swap(() => browser.press("3"));
  assert.equal(await browser.grades(), 3);
  assert.deepEqual(server.posts, ["0v1", "0v2", "0v1"]);
});

test("the same card at the same revision stays revealed across a refresh", async (t) => {
  const exe = chromium();
  if (!exe) { t.skip("no Chromium found"); return; }
  const server = await ship("0v1");
  t.after(server.close);
  const browser = await tab(t, exe);
  await browser.open(`${server.origin}${REVIEW}`);
  await browser.flip();
  await browser.refresh();
  assert.equal(await browser.shown(), reveal("0v1"));
  assert.equal(await browser.revealed(), true);
  server.answers.push([200, null]);
  await browser.swap(() => browser.press("3"));
  assert.equal(await browser.grades(), 1);
  assert.deepEqual(server.posts, ["0v1"]);
});

test("a back left open is closed when Back brings its page back", async (t) => {
  const exe = chromium();
  if (!exe) { t.skip("no Chromium found"); return; }
  const server = await ship("0v1");
  t.after(server.close);
  const browser = await tab(t, exe);
  await browser.open(`${server.origin}${REVIEW}`);
  await browser.flip();
  assert.equal(await browser.revealed(), true);
  await browser.follow(INBOX);
  assert.equal(await browser.shown(), null);
  // htmx puts the review back from its history cache, back open
  await browser.back();
  assert.match(await browser.cached(), /<details class="flip"[^>]* open=""/);
  assert.equal(await browser.shown(), reveal("0v1"));
  assert.equal(await browser.revealed(), false);
  await browser.press("3");
  assert.equal(await browser.grades(), 0);
  // only a new flip grades it
  await browser.flip();
  server.answers.push([200, null]);
  await browser.swap(() => browser.press("3"));
  assert.equal(await browser.grades(), 1);
  assert.deepEqual(server.posts, ["0v1"]);
});

test("a revision revealed before Back is closed when a 409 brings it back", async (t) => {
  const exe = chromium();
  if (!exe) { t.skip("no Chromium found"); return; }
  const server = await ship("0v2");
  t.after(server.close);
  const browser = await tab(t, exe);
  await browser.open(`${server.origin}${HOME}`);
  assert.equal(await browser.shown(), reveal("0v2"));
  // by the Review link the ship shows 0v1; flip it, and a refresh at the
  // same revision keeps it open
  server.revision = "0v1";
  await browser.follow(REVIEW);
  assert.equal(await browser.shown(), reveal("0v1"));
  await browser.flip();
  await browser.refresh();
  assert.equal(await browser.revealed(), true);
  // Back puts 0v2 back from the history cache, closed
  await browser.back();
  assert.equal(await browser.shown(), reveal("0v2"));
  assert.equal(await browser.revealed(), false);
  // flip and grade it; the ship refuses it and shows 0v1
  await browser.flip();
  server.answers.push([409, "0v1"]);
  await browser.swap(() => browser.press("3"));
  assert.equal(await browser.shown(), reveal("0v1"));
  assert.equal(await browser.revealed(), false);
  await browser.press("3");
  assert.equal(await browser.grades(), 1);
  // only a new flip grades it
  await browser.flip();
  server.answers.push([200, null]);
  await browser.swap(() => browser.press("3"));
  assert.equal(await browser.grades(), 2);
  assert.deepEqual(server.posts, ["0v2", "0v1"]);
});

test("Back to the same card at the same revision keeps it revealed", async (t) => {
  const exe = chromium();
  if (!exe) { t.skip("no Chromium found"); return; }
  const server = await ship("0v1");
  t.after(server.close);
  const browser = await tab(t, exe);
  await browser.open(`${server.origin}${HOME}`);
  await browser.follow(REVIEW);
  await browser.flip();
  assert.equal(await browser.revealed(), true);
  // Back puts /apps/seer back from the history cache with the back closed,
  // but the card was on screen at that revision throughout
  await browser.back();
  assert.doesNotMatch(await browser.cached(), /<details class="flip"[^>]* open=""/);
  assert.equal(await browser.shown(), reveal("0v1"));
  assert.equal(await browser.revealed(), true);
  server.answers.push([200, null]);
  await browser.swap(() => browser.press("3"));
  assert.equal(await browser.grades(), 1);
  assert.deepEqual(server.posts, ["0v1"]);
});
