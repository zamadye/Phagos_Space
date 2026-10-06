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
page.on("console", (message) => { if (message.type() === "error") errors.push(`console: ${message.text()}`); });
page.on("pageerror", (error) => errors.push(`pageerror: ${error.message}`));
await page.goto("http://127.0.0.1:8000/wall-study.html?build=wall-study", { waitUntil: "load", timeout: 120000 });
await new Promise((resolve) => setTimeout(resolve, 6000));
await page.screenshot({ path: path.join(evidenceDir, "wall-study-smoke.png") });
await new Promise((resolve) => setTimeout(resolve, 1200));
await page.screenshot({ path: path.join(evidenceDir, "wall-study-breathing-after.png") });
await page.keyboard.down("Space");
await new Promise((resolve) => setTimeout(resolve, 900));
await page.screenshot({ path: path.join(evidenceDir, "wall-study-pulse.png") });
await page.keyboard.up("Space");
console.log(JSON.stringify({ title: await page.title(), canvas: Boolean(await page.$("canvas")), errors, evidence: ["evidence/wall-study-smoke.png", "evidence/wall-study-pulse.png"] }, null, 2));
const browserProcess = typeof browser.process === "function" ? browser.process() : null;
browser.disconnect();
if (browserProcess?.pid) { try { process.kill(browserProcess.pid, "SIGKILL"); } catch {} }
process.exitCode = errors.length ? 1 : 0;
process.exit();
