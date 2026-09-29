# PHAGOS web application layer

This directory is the browser/WebView application—not a static wrapper around a repository page.

- `src/` is where HTML/CSS/TypeScript UI/UX is built.
- `public/engine/` is the generated Godot engine payload embedded in `GameViewport`.
- `engine_bridge.js` is copied into that payload after every Godot export.
- `src/engineBridge.ts` defines the parent-web-app side of the message protocol.

The arena is rendered only by Godot. Build genuine interface elements here when they are designed: menus, HUD, accessibility controls, onboarding, settings, and other application flow. Do not redraw the biological world in DOM/CSS/canvas.

## Message contract

The parent app sends:

```js
{ channel: "phagos-ui", type: "command-name", payload: {} }
```

The embedded engine sends:

```js
{ channel: "phagos-engine", type: "event-name", payload: {} }
```

The bridge currently establishes the contract but intentionally does not invent gameplay commands before the UI/hero design is defined.
