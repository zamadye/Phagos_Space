import { GameViewport } from "./components/GameViewport";

export function App() {
  return (
    <main className="application-shell">
      <GameViewport />
      {/*
        Native HTML/CSS/JS UI mounts here in later phases. The arena is never
        redrawn in the web layer: it remains the Godot engine viewport.
      */}
      <div id="phagos-ui-root" aria-live="polite" />
    </main>
  );
}
