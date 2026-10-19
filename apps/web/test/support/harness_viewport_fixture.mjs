import fs from "node:fs/promises";
import path from "node:path";
import {fileURLToPath, pathToFileURL} from "node:url";
import {spawn} from "node:child_process";
import assert from "node:assert/strict";
const appRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const root = process.argv[2];
let html = await fs.readFile(path.join(root, "page.html"), "utf8");
// A stylesheet BOM is decoded away by HTTP; remove it when embedding the same bytes in a style element.
const css = (await fs.readFile(path.join(appRoot, "app/assets/builds/application.css"), "utf8")).replace(/^\uFEFF/, "");
html = html.replace(/<link\b[^>]*rel=["']stylesheet["'][^>]*>/gi, () => "<style>" + css + "</style>");
html = html.replace(/<script\b[^>]*>.*?<\/script>/gis, "");
const logo = await fs.readFile(path.join(appRoot, "public/logo.png"));
html = html.replace('src="/logo.png"', 'src="data:image/png;base64,' + logo.toString("base64") + '"');
const pageFile = path.join(root, "rendered.html");
await fs.writeFile(pageFile, html, {mode: 0o600});
const profile = await fs.mkdtemp(path.join(root, "chromium-"));
const browser = spawn("chromium", ["--headless", "--remote-debugging-port=0", "--user-data-dir=" + profile,
  "--no-first-run", "--disable-background-networking", "--disable-component-update", "--disable-sync", "about:blank"],
  {stdio: ["ignore", "ignore", "pipe"]});
let stderr = "";
browser.stderr.on("data", data => { stderr = (stderr + data.toString()).slice(-4096); });
let socket;
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
try {
  let port;
  for (let index = 0; index < 100; index++) {
    try { port = (await fs.readFile(path.join(profile, "DevToolsActivePort"), "utf8")).split("\n")[0]; break; }
    catch { await delay(50); }
  }
  assert(port, "Owned Chromium did not start: " + stderr);
  const pages = await (await fetch("http://127.0.0.1:" + port + "/json/list")).json();
  const target = pages.find(page => page.type === "page");
  socket = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => {
    socket.addEventListener("open", resolve, {once: true});
    socket.addEventListener("error", reject, {once: true});
  });
  let sequence = 0;
  const pending = new Map();
  const events = new Map();
  socket.addEventListener("message", event => {
    const message = JSON.parse(event.data);
    if (message.id && pending.has(message.id)) {
      const handler = pending.get(message.id);
      pending.delete(message.id);
      clearTimeout(handler.timer);
      if (message.error) handler.reject(new Error(JSON.stringify(message.error))); else handler.resolve(message.result);
    } else if (events.has(message.method)) {
      const handler = events.get(message.method);
      events.delete(message.method);
      clearTimeout(handler.timer);
      handler.resolve(message.params);
    }
  });
  function send(method, params = {}) {
    const id = ++sequence;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error("CDP timeout: " + method)), 10000);
      pending.set(id, {resolve, reject, timer});
      socket.send(JSON.stringify({id, method, params}));
    });
  }
  function waitEvent(method) {
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error("Browser event timeout: " + method)), 10000);
      events.set(method, {resolve, reject, timer});
    });
  }
  await send("Page.enable");
  const metrics = [];
  for (const width of [390, 1280]) {
    await send("Emulation.setDeviceMetricsOverride", {width, height: 900, deviceScaleFactor: 1, mobile: width < 640});
    const loaded = waitEvent("Page.loadEventFired");
    await send("Page.navigate", {url: pathToFileURL(pageFile).href});
    await loaded;
    const result = await send("Runtime.evaluate", {returnByValue: true, expression: String.raw`(() => {
      const selects = Array.from(document.querySelectorAll("main select"));
      return {
        width: window.innerWidth,
        scrollWidth: document.documentElement.scrollWidth,
        mainWidth: document.querySelector("main").getBoundingClientRect().width,
        styled: getComputedStyle(document.body).backgroundColor !== "rgba(0, 0, 0, 0)",
        forms: document.querySelectorAll("main form").length,
        labeled: selects.every(select => document.querySelector('label[for="' + select.id + '"]')),
        controlsFit: selects.every(select => { const box = select.getBoundingClientRect(); return box.left >= 0 && box.right <= window.innerWidth; }),
        columns: getComputedStyle(document.querySelector(".harness-profile-list")).gridTemplateColumns.split(" ").length
      };
    })()`});
    const value = result.result.value;
    assert.equal(value.width, width);
    assert(value.scrollWidth <= width, "Horizontal overflow: " + JSON.stringify(value));
    assert(value.mainWidth <= Math.min(width, 860), "Content exceeds the repository surface width");
    assert(value.styled, "Compiled stylesheet variables were not applied");
    assert.equal(value.forms, 2);
    assert(value.labeled);
    assert(value.controlsFit);
    assert.equal(value.columns, width < 640 ? 1 : 2);
    metrics.push(value);
    const screenshot = await send("Page.captureScreenshot", {format: "png", captureBeyondViewport: true});
    await fs.writeFile(path.join(root, "harness-" + width + ".png"), Buffer.from(screenshot.data, "base64"), {mode: 0o600});
  }
  await fs.writeFile(path.join(root, "metrics.json"), JSON.stringify(metrics, null, 2), {mode: 0o600});
  process.stdout.write(JSON.stringify(metrics) + "\n");
} finally {
  socket?.close();
  if (browser.exitCode === null && browser.signalCode === null) {
    const exited = new Promise(resolve => browser.once("exit", resolve));
    browser.kill("SIGTERM");
    const timer = setTimeout(() => browser.kill("SIGKILL"), 3000);
    await exited;
    clearTimeout(timer);
  }
  await fs.rm(profile, {recursive: true, force: true});
}
