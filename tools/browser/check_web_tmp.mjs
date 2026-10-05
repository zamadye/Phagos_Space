import puppeteer from "puppeteer-core";
process.env.VERCEL ??= "1";
const { default: chromium } = await import("@sparticuz/chromium");
chromium.setGraphicsMode = true;
const browser = await puppeteer.launch({ args: [...chromium.args, "--no-sandbox", "--disable-dev-shm-usage", "--use-angle=swiftshader", "--enable-webgl"], executablePath: await chromium.executablePath(), headless: "shell", defaultViewport: {width:1024,height:1024} });
const page = await browser.newPage();
const errors=[]; page.on("console",m=>{if(m.type()==="error") errors.push("console:"+m.text())}); page.on("pageerror",e=>errors.push("page:"+e.message));
await page.goto("http://127.0.0.1:8000/index.html", {waitUntil:"domcontentloaded", timeout:30000}); console.log("loaded"); await new Promise(r=>setTimeout(r,15000)); await page.screenshot({path:"evidence/blender-wall-check.png"}); console.log(JSON.stringify({errors,canvas:!!(await page.$("canvas"))})); await browser.close();
