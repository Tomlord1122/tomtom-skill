---
name: mcp-app-ui-host
description: Host an MCP App UI inside Cometline when a tool declares a ui:// resource. Use when the user wants a whiteboard, view, or other MCP App to open and be operated in the workspace panel, or when wiring io.modelcontextprotocol/ui, resourceUri, and a sandboxed HTML host. Do not use for finding which MCP tool to call.
tags:
  - mcp
  - cometline
metadata:
  cometline:
    origin: self-improvement
---

# MCP App UI host

Advertising `io.modelcontextprotocol/ui` is not the same as opening the view. The server only returns HTML after the host names the MIME profile on initialize and then reads the tool's `ui://` resource. A guessed URL or a chart `srcdoc` viewer is not that host.

## 1. Advertise the extension on connect

1. On the MCP client capabilities, call `AddExtension` with `io.modelcontextprotocol/ui`.
2. Set `mimeTypes` to `["text/html;profile=mcp-app"]` only. Do not advertise bare `text/html`.
3. Apply that capability object to every connect path, including the test transport helper. A second `NewClient` that still passes an empty `ClientCapabilities` will negotiate without the extension.

## 2. Keep the UI link on the catalog

1. Copy tool `_meta` onto the discovered tool. Catalog entries that keep only name, description, and input schema cannot open a view later.
2. Read the resource URI in this order: `_meta.ui.resourceUri`, then `_meta["ui/resourceUri"]`, then `_meta["openai/outputTemplate"]`. Stop at the first non-empty string.
3. Treat missing `_meta.ui.visibility` as model-visible. If the array exists and does not contain `"model"`, keep the tool callable but off the model catalog.
4. A JSON number or string in `visibility` is not the array form. Do not invent a second parser until a live tool returns that shape.

## 3. Fetch HTML only for the tool that was called

1. After `use_mcp_tool` resolves the catalog entry, read the resource only when `AppResourceURI` is set. Text-only tools stay on the normal call path.
2. Call `resources/read` with that URI. Accept a content item only when its MIME type has the prefix `text/html;profile=mcp-app`.
3. Store the HTML in a session-scoped in-memory document with a random id. Do not put the HTML in the SSE frame or in the model-visible tool output.
4. Emit a separate `mcp_app_ready` event whose `mcpAppUi` carries `serverId`, `toolName`, `resourceUri`, `preferredModelDisplayMode`, `appId`, and `title`. Tell the model one line: the panel opened, or it did not.
5. If the MIME check fails, still return the tool text. Append that the UI did not open. Do not open an empty panel.

## 4. Open the panel without clearing the app

1. On `mcp_app_ready`, fetch `GET /api/v1/sessions/{id}/mcp-apps/{appId}` with the same API base URL as other CometMind calls. A relative `/api/v1` URL misses the sidecar.
2. Key the open view by `resourceUri` so a second call for the same view replaces the document instead of stacking a tab.
3. Show the HTML in a sandboxed iframe (`allow-scripts allow-forms`, `referrerpolicy="no-referrer"`, `srcdoc`). Do not navigate a webview to the `ui://` URI.
4. Open the workspace panel with `ensureWorkspacePanelVisible()`, which takes no session id. Do not call `openWorkspacePanelUrl` with an empty URL; that path clears the view you just stored.
5. Cast the event before comparing `type` to `mcp_app_ready`. The generated `StreamEvent` union does not include that kind until OpenAPI is regenerated, and a direct comparison fails typecheck.

## 5. Leave the bridge for the next slice

1. A sandboxed iframe can display the page. It cannot call host tools or receive tool results until a `postMessage` bridge exists.
2. Do not add `allow-same-origin` to make the bridge easier. That weakens the sandbox.
3. Do not infer a method list or a double-iframe rule from Codex or Grok. Those checkouts advertise the extension and keep `resourceUri`; they do not host the iframe.

## Pitfalls

- Connecting without the UI extension makes a later `resources/read` look like a server bug. The server omitted the UI resource because the host never asked for the profile.
- Dropping `_meta` at catalog time cannot be repaired at call time. The URI has to survive discovery.
- Putting HTML on `tool_result` both bloats the model context and still does not open a panel. The desktop needs a small pointer plus a fetch by app id.
- `ensureWorkspacePanelVisible()` uses the active session and returns immediately when that session has no panel record. Passing the SSE session id is a type error, not a way to target another session.
- Visibility JSON from the wire is `[]any`, not `[]string`. A typed assertion to `[]string` is always false and hides every app-only tool from the model by mistake.