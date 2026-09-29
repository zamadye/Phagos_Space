import { useEffect, useRef, useState } from "react";
import { listenForEngineEvents, type EngineEvent } from "../engineBridge";

const ENGINE_URL = "/engine/index.html";

export function GameViewport() {
  const frameRef = useRef<HTMLIFrameElement>(null);
  const [engineReady, setEngineReady] = useState(false);

  useEffect(() => {
    return listenForEngineEvents((event: EngineEvent) => {
      if (event.type === "engine-ready") {
        setEngineReady(true);
      }
    });
  }, []);

  return (
    <section className="game-viewport" aria-label="PHAGOS game engine viewport">
      <iframe
        ref={frameRef}
        className="game-viewport__engine"
        src={ENGINE_URL}
        title="PHAGOS game engine"
        allow="autoplay; fullscreen; gamepad"
      />
      <div className="game-viewport__ui-anchor" data-engine-ready={engineReady} />
    </section>
  );
}
