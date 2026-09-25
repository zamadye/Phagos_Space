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

const targets = [
    { name: 'Chrome', engine: chromium, launch: { channel: 'chrome' } },
    { name: 'Firefox', engine: firefox, launch: {} },
    { name: 'Edge', engine: chromium, launch: { channel: 'msedge' } },
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
    const wasmResponses = [];
    let browser;
    try {
        browser = await target.engine.launch({ headless: true, ...target.launch });
        const context = await browser.newContext({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 });
        const page = await context.newPage();
        page.on('console', (message) => {
            if (message.type() === 'error') consoleErrors.push(message.text());
        });
        page.on('pageerror', (error) => pageErrors.push(error.message));
        page.on('response', (response) => {
            if (/\.wasm(?:\?|$)/.test(response.url())) {
                wasmResponses.push({
                    status: response.status(),
                    mime: response.headers()['content-type'] || '',
                    url: response.url(),
                });
            }
        });

        await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
        await page.waitForSelector('#canvas', { state: 'visible', timeout: 15000 });
        await page.waitForFunction(() => !document.querySelector('#phagos-loader'), null, { timeout: 60000 });
        await page.waitForTimeout(1000);

        const fps = await measureAnimationFrameFps(page);
        const webgl = await page.evaluate(() => {
            const canvas = document.querySelector('#canvas');
            const gl = canvas?.getContext('webgl2') || canvas?.getContext('webgl');
            if (!gl) return { available: false, error: 'WebGL context unavailable' };
            const error = gl.getError();
            return { available: true, error: error === gl.NO_ERROR ? null : `WebGL error ${error}` };
        });
        await context.close();

        const wasm = wasmResponses[0] || null;
        const errors = [...consoleErrors, ...pageErrors];
        const checks = {
            wasm_load: Boolean(wasm && wasm.status === 200),
            wasm_mime: Boolean(wasm && /application\/wasm/i.test(wasm.mime)),
            shader_compile: webgl.available && webgl.error === null && errors.length === 0,
            fps: fps >= minFps,
            console_error_free: errors.length === 0,
        };
        return { name: target.name, checks, fps, wasm, webgl, consoleErrors, pageErrors, fatal: null };
    } catch (error) {
        return {
            name: target.name,
            checks: { wasm_load: false, wasm_mime: false, shader_compile: false, fps: false, console_error_free: false },
            fps: 0,
            wasm: null,
            webgl: { available: false, error: String(error) },
            consoleErrors,
            pageErrors,
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
const now = new Date().toISOString();
const rows = results.map((result) => {
    const mark = (value) => value ? 'PASS' : 'FAIL';
    return `| ${result.name} | ${mark(result.checks.wasm_load)} | ${mark(result.checks.wasm_mime)} | ${mark(result.checks.shader_compile)} | ${result.fps.toFixed(1)} | ${mark(result.checks.fps)} | ${mark(result.checks.console_error_free)} |`;
}).join('\n');
const diagnostics = results.map((result) => {
    const messages = [result.fatal, ...result.consoleErrors, ...result.pageErrors, result.webgl?.error].filter(Boolean);
    if (!messages.length) return `- **${result.name}:** no console or WebGL errors observed.`;
    return `- **${result.name}:** ${messages.map((message) => `\`${String(message).replaceAll('`', '\\`')}\``).join('; ')}`;
}).join('\n');
const wasmDetails = results.map((result) => `- **${result.name}:** ${result.wasm ? `${result.wasm.status} · ${result.wasm.mime || 'missing MIME'} · ${result.wasm.url}` : 'WASM response not observed'}`).join('\n');
const report = `# Phagos browser validation\n\nGenerated: ${now}\n\nTarget URL: ${url}\n\nHeadless rAF gate: **≥ ${minFps} FPS** (desktop browser target remains 60 FPS).\n\n| Browser | WASM load | WASM MIME | Shader / WebGL | Measured FPS | FPS gate | Console errors |\n|---|---:|---:|---:|---:|---:|---:|\n${rows}\n\n## WASM delivery\n${wasmDetails}\n\n## Diagnostics\n${diagnostics}\n\n## Result\n\n**${allPassed ? 'PASS' : 'FAIL'}** — Chrome, Firefox, and Edge must all pass before the Web preview is promoted.\n`;
await mkdir(dirname(reportPath), { recursive: true });
await writeFile(reportPath, report, 'utf8');
console.log(`Browser QA ${allPassed ? 'passed' : 'failed'}: ${reportPath}`);
if (!allPassed) process.exitCode = 1;
