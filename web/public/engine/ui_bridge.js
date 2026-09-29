/*
 * Browser-side bridge owned by the web app.
 * Godot may call PHAGOS_ENGINE_BRIDGE.emit(...) through JavaScriptBridge later.
 * The web UI sends phagos-ui messages back to this frame with postMessage.
 */
(() => {
  "use strict";

  const WEB_UI_CHANNEL = "phagos-ui";
  const ENGINE_CHANNEL = "phagos-engine";
  const parentOrigin = window.location.origin;
  const listeners = new Set();

  function emit(type, payload) {
    if (window.parent === window) return;
    window.parent.postMessage({ channel: ENGINE_CHANNEL, type, payload }, parentOrigin);
  }

  function onUiCommand(listener) {
    listeners.add(listener);
    return () => listeners.delete(listener);
  }

  window.addEventListener("message", (event) => {
    if (event.origin !== parentOrigin) return;
    const message = event.data;
    if (!message || message.channel !== WEB_UI_CHANNEL || typeof message.type !== "string") return;
    for (const listener of listeners) listener(message);
    window.dispatchEvent(new CustomEvent("phagos-ui-command", { detail: message }));
  });

  window.PHAGOS_ENGINE_BRIDGE = Object.freeze({ emit, onUiCommand });
  emit("engine-shell-ready");
})();
