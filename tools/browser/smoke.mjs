import puppeteer from "puppeteer-core";
import chromium from "@sparticuz/chromium";

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
await page.goto("http://127.0.0.1:8000/index.html", { waitUntil: "networkidle0", timeout: 120000 });
await new Promise((resolve) => setTimeout(resolve, 8000));
await page.screenshot({ path: "evidence-m1-web.png" });
const canvas = await page.$("canvas");
const canvasBox = canvas ? await canvas.boundingBox() : null;
console.log(JSON.stringify({ title: await page.title(), canvas: Boolean(canvas), canvasBox, errors }, null, 2));
await browser.close();
if (errors.length) process.exitCode = 1;
