#!/usr/bin/env node
/**
 * Browser acceptance test for the exported Phagos Web build.
 * Validates actual WASM delivery/MIME, Godot startup, WebGL shader errors surfaced by
 * the browser, requestAnimationFrame throughput, and console/page errors in Chrome,
 * Firefox, and Microsoft Edge.
 */
import { chromium, firefox } from 'playwright';
import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';

const args = process.argv.slice(2);
const valueAfter = (flag, fallback) => {
    const index = args.indexOf(flag);
    return index >= 0 && args[index + 1] ? args[index + 1] : fallback;
};
const url = valueAfter('--url', 'http://127.0.0.1:8080');
const reportPath = resolve(valueAfter('--report', 'reports/browser_validation.md'));
const minFps = Number(valueAfter('--min-fps', '55'));
const softwareSmokeMinFps = Number(valueAfter('--software-min-fps', '1'));
// Xvfb + LIBGL_ALWAYS_SOFTWARE has no desktop GPU. This explicit opt-in keeps the
// browser boot smoke gate meaningful there without falsely treating its rAF timing as
// a desktop 60 FPS measurement. The default remains the strict desktop FPS gate.
const allowSoftwareFps = args.includes('--allow-software-fps');
// CI runs this under Xvfb with --headed so all three engines receive a visible
// compositor surface. Local automation remains headless by default.
const headed = args.includes('--headed');

const firefoxWebglPrefs = {
    'webgl.disabled': false,
    'webgl.force-enabled': true,
    'layers.acceleration.force-enabled': true,
    'gfx.webrender.all': true,
};
const targets = [
    { name: 'Chrome', engine: chromium, launch: { channel: 'chrome', args: ['--ignore-gpu-blocklist', '--enable-webgl'] } },
    { name: 'Firefox', engine: firefox, launch: { firefoxUserPrefs: firefoxWebglPrefs } },
    { name: 'Edge', engine: chromium, launch: { channel: 'msedge', args: ['--ignore-gpu-blocklist', '--enable-webgl'] } },
];

async function measureAnimationFrameFps(page) {
    return page.evaluate(async () => new Promise((resolveFps) => {
        let frames = 0;
        const startedAt = performance.now();
        const tick = (now) => {
            frames += 1;
            if (now - startedAt >= 2000) {
                resolveFps(frames * 1000 / (now - startedAt));
                return;
            }
            requestAnimationFrame(tick);
        };
        requestAnimationFrame(tick);
    }));
}

async function inspectTarget(target) {
    const consoleErrors = [];
    const pageErrors = [];
    const failedResponses = [];
    const wasmResponses = [];
    let browser;
    try {
        browser = await target.engine.launch({ headless: !headed, ...target.launch });
        const context = await browser.newContext({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 });
        const page = await context.newPage();
        page.on('console', (message) => {
            if (message.type() === 'error') consoleErrors.push(message.text());
        });
        page.on('pageerror', (error) => pageErrors.push(error.message));
        page.on('response', (response) => {
            const entry = {
                status: response.status(),
                url: response.url(),
            };
            if (response.status() >= 400) failedResponses.push(entry);
            if (/\.wasm(?:\?|$)/.test(response.url())) {
                wasmResponses.push({
                    ...entry,
                    mime: response.headers()['content-type'] || '',
                });
            }
        });

        await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
        await page.waitForSelector('#canvas', { state: 'visible', timeout: 15000 });
        await page.waitForFunction(() => !document.querySelector('#phagos-loader'), null, { timeout: 60000 });
        await page.bringToFront();
        // Give the renderer a foreground warm-up interval before sampling rAF.
        await page.waitForTimeout(2000);

        const fps = await measureAnimationFrameFps(page);
        const webgl = await page.evaluate(() => {
            const canvas = document.querySelector('#canvas');
            const gl = canvas?.getContext('webgl2') || canvas?.getContext('webgl');
            if (!gl) return { available: false, error: 'WebGL context unavailable', renderer: null, vendor: null };
            const debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
            const renderer = debugInfo
                ? gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL)
                : gl.getParameter(gl.RENDERER);
            const vendor = debugInfo
                ? gl.getParameter(debugInfo.UNMASKED_VENDOR_WEBGL)
                : gl.getParameter(gl.VENDOR);
            const error = gl.getError();
            return { available: true, error: error === gl.NO_ERROR ? null : `WebGL error ${error}`, renderer, vendor };
        });
        await context.close();

        const wasm = wasmResponses[0] || null;
        // Report the exact failed URL rather than a browser's generic 404 message: static
        // export naming regressions otherwise look like a renderer or shader failure.
        const responseErrors = failedResponses.map((response) => `HTTP ${response.status} ${response.url}`);
        const errors = [...consoleErrors, ...pageErrors, ...responseErrors];
        const desktopFps = fps >= minFps;
        const softwareFpsExempt = !desktopFps && allowSoftwareFps && fps >= softwareSmokeMinFps;
        const checks = {
            wasm_load: Boolean(wasm && wasm.status === 200),
            wasm_mime: Boolean(wasm && /application\/wasm/i.test(wasm.mime)),
            shader_compile: webgl.available && webgl.error === null && errors.length === 0,
            fps: desktopFps || softwareFpsExempt,
            console_error_free: errors.length === 0,
        };
        return {
            name: target.name,
            checks,
            fps,
            desktopFps,
            softwareFpsExempt,
            wasm,
            webgl,
            consoleErrors,
            pageErrors,
            responseErrors,
            fatal: null,
        };
    } catch (error) {
        return {
            name: target.name,
            checks: { wasm_load: false, wasm_mime: false, shader_compile: false, fps: false, console_error_free: false },
            fps: 0,
            desktopFps: false,
            softwareFpsExempt: false,
            wasm: null,
            webgl: { available: false, error: String(error) },
            consoleErrors,
            pageErrors,
            responseErrors: [],
            fatal: error instanceof Error ? error.stack || error.message : String(error),
        };
    } finally {
        if (browser) await browser.close();
    }
}

const results = [];
for (const target of targets) {
    // Sequential runs keep WebGL software rendering and GitHub-hosted runners stable.
    results.push(await inspectTarget(target));
}

const allPassed = results.every((result) => Object.values(result.checks).every(Boolean));
const hasSoftwareFpsExemption = results.some((result) => result.softwareFpsExempt);
const now = new Date().toISOString();
const rows = results.map((result) => {
    const mark = (value) => value ? 'PASS' : 'FAIL';
    const fpsPolicy = result.desktopFps ? 'PASS' : result.softwareFpsExempt ? 'SMOKE' : 'FAIL';
    return `| ${result.name} | ${mark(result.checks.wasm_load)} | ${mark(result.checks.wasm_mime)} | ${mark(result.checks.shader_compile)} | ${result.fps.toFixed(1)} | ${fpsPolicy} | ${mark(result.checks.console_error_free)} |`;
}).join('\n');
const diagnostics = results.map((result) => {
    const messages = [result.fatal, ...result.consoleErrors, ...result.pageErrors, ...result.responseErrors, result.webgl?.error].filter(Boolean);
    if (!messages.length) return `- **${result.name}:** no console or WebGL errors observed.`;
    return `- **${result.name}:** ${messages.map((message) => `\`${String(message).replaceAll('`', '\\`')}\``).join('; ')}`;
}).join('\n');
const wasmDetails = results.map((result) => `- **${result.name}:** ${result.wasm ? `${result.wasm.status} · ${result.wasm.mime || 'missing MIME'} · ${result.wasm.url}` : 'WASM response not observed'}`).join('\n');
const frameTiming = results.map((result) => {
    const renderer = [result.webgl?.vendor, result.webgl?.renderer].filter(Boolean).join(' · ') || 'renderer unavailable';
    const policy = result.desktopFps
        ? `desktop gate PASS (≥ ${minFps} FPS)`
        : result.softwareFpsExempt
            ? `software smoke PASS (≥ ${softwareSmokeMinFps} FPS); desktop ≥ ${minFps} FPS remains unverified`
            : `FAIL (requires ≥ ${minFps} FPS${allowSoftwareFps ? ` or ≥ ${softwareSmokeMinFps} FPS on the configured software smoke surface` : ''})`;
    return `- **${result.name}:** ${result.fps.toFixed(1)} FPS · ${renderer} · ${policy}`;
}).join('\n');
const surfaceMode = headed ? 'headed via Xvfb' : 'headless';
const resultSummary = allPassed
    ? hasSoftwareFpsExemption
        ? `**PASS (software smoke)** — Chrome, Firefox, and Edge loaded the official Web build with valid WASM, WebGL, and clean consoles. The configured software surface cannot certify desktop 60 FPS; run this command without \`--allow-software-fps\` on accelerated desktop hardware for that gate.`
        : '**PASS** — Chrome, Firefox, and Edge passed all Web delivery, WebGL, console, and desktop FPS gates.'
    : '**FAIL** — Chrome, Firefox, and Edge must all pass the configured Web delivery, WebGL, console, and frame-timing gates before promotion.';
const softwarePolicy = allowSoftwareFps
    ? ` A software smoke floor of **≥ ${softwareSmokeMinFps} FPS** is active; it does not replace the desktop gate.`
    : '';
const report = `# Phagos browser validation\n\nGenerated: ${now}\n\nTarget URL: ${url}\n\nBrowser surface: **${surfaceMode}**. Desktop rAF gate: **≥ ${minFps} FPS** (desktop target remains 60 FPS).${softwarePolicy}\n\n| Browser | WASM load | WASM MIME | Shader / WebGL | Measured FPS | FPS policy | Console errors |\n|---|---:|---:|---:|---:|---:|---:|\n${rows}\n\n## WASM delivery\n${wasmDetails}\n\n## Frame timing\n${frameTiming}\n\n## Diagnostics\n${diagnostics}\n\n## Result\n\n${resultSummary}\n`;
await mkdir(dirname(reportPath), { recursive: true });
await writeFile(reportPath, report, 'utf8');
console.log(`Browser QA ${allPassed ? 'passed' : 'failed'}: ${reportPath}`);
if (!allPassed) process.exitCode = 1;
