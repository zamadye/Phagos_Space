import puppeteer from "puppeteer-core";

// @sparticuz/chromium ships an AL2023-compatible lib bundle in
// al2023.tar.br. Enable its extraction path before the dynamic import so the
// smoke test does not depend on system libnspr4/libnss3 packages.
process.env.VERCEL ??= "1";
const { default: chromium } = await import("@sparticuz/chromium");
chromium.setGraphicsMode = true;
const browser = await puppeteer.launch({
  args: [...chromium.args, "--no-sandbox", "--disable-dev-shm-usage", "--use-angle=swiftshader", "--enable-webgl"],
  executablePath: await chromium.executablePath(),
  headless: "shell",
  defaultViewport: { width: 1024, height: 1024, deviceScaleFactor: 1 },
});

const page = await browser.newPage();
const errors = [];
page.on("console", (message) => {
  if (message.type() === "error") errors.push(`console: ${message.text()}`);
});
page.on("pageerror", (error) => errors.push(`pageerror: ${error.message}`));
// Godot's WebGL bootstrap keeps worklet/runtime requests alive; DOMContentLoaded
// is the reliable page-ready boundary for the smoke check.
await page.goto("http://127.0.0.1:8000/index.html", { waitUntil: "load", timeout: 120000 });
await new Promise((resolve) => setTimeout(resolve, 8000));
await page.screenshot({ path: "evidence/m1-web-smoke.png" });
const canvas = await page.$("canvas");
const canvasBox = canvas ? await canvas.boundingBox() : null;
console.log(JSON.stringify({ title: await page.title(), canvas: Boolean(canvas), canvasBox, errors }, null, 2));
// Chromium's WebGL shell can keep browser.close() pending after the Godot
// audio worklets have been loaded. Disconnect and terminate the child directly
// so CI/QA reports completion instead of timing out after the result is printed.
const browserProcess = typeof browser.process === "function" ? browser.process() : null;
browser.disconnect();
if (browserProcess?.pid) {
  try { process.kill(browserProcess.pid, "SIGKILL"); } catch {}
}
process.exitCode = errors.length ? 1 : 0;
process.exit();
