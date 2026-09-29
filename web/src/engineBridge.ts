export const ENGINE_BRIDGE_CHANNEL = "phagos-engine";

export type EngineEvent = {
  channel: typeof ENGINE_BRIDGE_CHANNEL;
  type: string;
  payload?: unknown;
};

export type UiCommand = {
  channel: "phagos-ui";
  type: string;
  payload?: unknown;
};

export function sendUiCommand(
  engineFrame: HTMLIFrameElement | null,
  type: string,
  payload?: unknown,
): void {
  const message: UiCommand = { channel: "phagos-ui", type, payload };
  engineFrame?.contentWindow?.postMessage(message, window.location.origin);
}

export function listenForEngineEvents(onEvent: (event: EngineEvent) => void): () => void {
  const receiveMessage = (event: MessageEvent<unknown>) => {
    if (event.origin !== window.location.origin || !isEngineEvent(event.data)) {
      return;
    }
    onEvent(event.data);
  };
  window.addEventListener("message", receiveMessage);
  return () => window.removeEventListener("message", receiveMessage);
}

function isEngineEvent(value: unknown): value is EngineEvent {
  return (
    typeof value === "object" &&
    value !== null &&
    "channel" in value &&
    (value as { channel?: unknown }).channel === ENGINE_BRIDGE_CHANNEL &&
    "type" in value &&
    typeof (value as { type?: unknown }).type === "string"
  );
}
