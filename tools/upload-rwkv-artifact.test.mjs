// tools/upload-rwkv-artifact against a local stand-in for the ship's store,
// which, like the ship, answers 403 without the owner's cookie and refuses
// a body that does not hash to its path.
import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const script = fileURLToPath(new URL("upload-rwkv-artifact", import.meta.url));
const cookie = "urbauth-~zod=0v1.secret";
const types = {
  "manifest.json": "application/json",
  "engine.wasm": "application/wasm",
  "weights.bin": "application/octet-stream",
  LICENSE: "text/plain; charset=utf-8",
  NOTICE: "text/plain; charset=utf-8",
  "THIRD-PARTY-LICENSES": "text/plain; charset=utf-8",
  "rwkv-engine-source.tar": "application/x-tar",
  "WEIGHTS-NOTICE.md": "text/markdown; charset=utf-8",
};
const sha256 = (bytes) => createHash("sha256").update(bytes).digest("hex");

function artifactDir(names = Object.keys(types)) {
  const dir = mkdtempSync(join(tmpdir(), "rwkv artifact "));
  for (const name of names) writeFileSync(join(dir, name), `${name} bytes\n`);
  return dir;
}

async function withStore(fn) {
  const stored = new Map();
  const server = createServer((req, res) => {
    const chunks = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", () => {
      const body = Buffer.concat(chunks);
      const sha = req.url.match(/^\/apps\/seer\/rwkv\/([0-9a-f]{64})$/)?.[1];
      if (req.headers.cookie !== cookie) return res.writeHead(403).end();
      if (req.method !== "PUT" || !sha) return res.writeHead(405).end();
      if (sha256(body) !== sha) return res.writeHead(400).end('{"code":"hash-mismatch"}');
      const status = stored.has(sha) ? 204 : 201;
      stored.set(sha, { type: req.headers["content-type"], body: body.toString() });
      res.writeHead(status).end();
    });
  });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  try {
    return await fn(`http://127.0.0.1:${server.address().port}`, stored);
  } finally {
    server.close();
  }
}

function upload(args, env) {
  return new Promise((resolve) => {
    execFile(script, args, { env: { PATH: process.env.PATH, ...env } }, (error, stdout, stderr) =>
      resolve({ code: error ? error.code : 0, stdout, stderr }));
  });
}

test("uploads every artifact file under its sha-256 with its type and the cookie", async () => {
  const dir = artifactDir();
  try {
    await withStore(async (ship, stored) => {
      const first = await upload([ship, dir], { SEER_COOKIE: cookie });
      assert.equal(first.code, 0, first.stderr);
      const again = await upload([`${ship}/`, dir], { SEER_COOKIE: cookie });
      assert.equal(again.code, 0, again.stderr);
      assert.deepEqual(new Map([...stored].sort()), new Map(Object.entries(types).map(([name, type]) =>
        [sha256(`${name} bytes\n`), { type, body: `${name} bytes\n` }]).sort()));
      const manifest = sha256("manifest.json bytes\n");
      assert.match(first.stdout, new RegExp(`^artifact-url   /apps/seer/rwkv/${manifest}$`, "m"));
      assert.match(first.stdout, new RegExp(`^artifact-hash  ${manifest}$`, "m"));
      assert.equal((again.stdout.match(/^present /gm) ?? []).length, 8, "a second upload stores nothing new");
      for (const out of [first, again]) assert.ok(!(out.stdout + out.stderr).includes("secret"), "cookie never printed");
    });
  } finally {
    rmSync(dir, { recursive: true });
  }
});

test("refuses to start without a cookie or a complete artifact, and stops on a refusal", async () => {
  const dir = artifactDir();
  const partial = artifactDir(["manifest.json", "engine.wasm", "weights.bin"]);
  try {
    await withStore(async (ship, stored) => {
      const noCookie = await upload([ship, dir], {});
      assert.equal(noCookie.code, 2);
      const incomplete = await upload([ship, partial], { SEER_COOKIE: cookie });
      assert.equal(incomplete.code, 1);
      assert.match(incomplete.stderr, /missing .*LICENSE/);
      assert.equal(stored.size, 0, "nothing uploaded before every file is present");
      const stranger = await upload([ship, dir], { SEER_COOKIE: "urbauth-~nec=0v2" });
      assert.equal(stranger.code, 1);
      assert.match(stranger.stderr, /manifest.json refused: HTTP 403/);
      assert.equal(stored.size, 0);
    });
  } finally {
    rmSync(dir, { recursive: true });
    rmSync(partial, { recursive: true });
  }
});
