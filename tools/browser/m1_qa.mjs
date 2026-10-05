import puppeteer from "puppeteer-core";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { mkdirSync } from "node:fs";

const evidenceDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../evidence");
mkdirSync(evidenceDir, { recursive: true });

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
// is the reliable page-ready boundary for this software-rendered QA sequence.
await page.goto("http://127.0.0.1:8000/index.html", { waitUntil: "load", timeout: 120000 });
await page.click("canvas");
await new Promise((resolve) => setTimeout(resolve, 2000));
await page.screenshot({ path: path.join(evidenceDir, "m1-web-boot.png") });
await page.keyboard.press("F3");
await new Promise((resolve) => setTimeout(resolve, 500));
await page.keyboard.press("F2");
await new Promise((resolve) => setTimeout(resolve, 500));
await page.screenshot({ path: path.join(evidenceDir, "m1-reference-overlay.png") });
await page.keyboard.press("F2");
await page.keyboard.press("F3");

await new Promise((resolve) => setTimeout(resolve, 6000));
await page.screenshot({ path: path.join(evidenceDir, "m1-web-active.png") });

// The default lane reaches the central hazard and then completes the 274.4m run.
// Allow extra time for software-rendered Chromium; this sandbox can run below 60 FPS.
await new Promise((resolve) => setTimeout(resolve, 120000));
await page.screenshot({ path: path.join(evidenceDir, "m1-web-finish.png") });

await page.keyboard.press("r");
await new Promise((resolve) => setTimeout(resolve, 1500));
await page.screenshot({ path: path.join(evidenceDir, "m1-web-retry.png") });

const canvas = await page.$("canvas");
console.log(JSON.stringify({
  canvas: Boolean(canvas),
  canvasBox: canvas ? await canvas.boundingBox() : null,
  errors,
  evidence: [
    "evidence/m1-web-boot.png",
    "evidence/m1-reference-overlay.png",
    "evidence/m1-web-active.png",
    "evidence/m1-web-finish.png",
    "evidence/m1-web-retry.png",
  ],
}, null, 2));
// Chromium's WebGL shell can keep browser.close() pending after the Godot
// audio worklets have been loaded. Disconnect and terminate the child directly
// so the long finish/retry sequence exits after reporting its evidence.
const browserProcess = typeof browser.process === "function" ? browser.process() : null;
browser.disconnect();
if (browserProcess?.pid) {
  try { process.kill(browserProcess.pid, "SIGKILL"); } catch {}
}
process.exitCode = errors.length ? 1 : 0;
process.exit();
