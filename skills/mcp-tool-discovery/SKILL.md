---
name: mcp-tool-discovery
description: Find the right connected MCP tool when search returns the wrong server or a huge schema, then call the exact name. Use when an MCP server is connected but keyword search hides the tool, returns unrelated servers, or dumps full JSON schemas, and the user asked for status, metrics, or another named operation. Also use when a mutating operation such as delete or pause is missing from search and the vendor CLI is already installed.
tags:
  - mcp
  - discovery
metadata:
  cometline:
    origin: self-improvement
---

# MCP tool discovery

Connected does not mean every operation is searchable. Search ranks names and descriptions and can bury the read tool under write tools whose nested schemas mention the keyword. A miss is not proof the tool is absent, and a guessed name is not a catalogue. A connector that can create a resource may still omit delete, pause, or billing.

## 1. Confirm the server, then search once

1. Call `list_mcp_servers`. Note status, tool count, and whether OAuth is signed in. A disconnected server is the blocker; do not search past it.
2. Call `search_mcp_tools` once with the user's operation words and a small limit (about 5). Read only `name`, `server`, and `description`. Ignore the rest of a huge `input_schema`.
3. If hits are the wrong server, or only create/write tools, do not repeat the same vague query. Nested fields such as a machine `metrics` config are not a metrics query tool.
4. Treat a near-name as a different operation. `delete_feedback` is not `delete_project`. Do not call it because the verb matched.

## 2. Get the real name list

1. Fetch the vendor's public tool reference as markdown (`/guide.md`, `llms.txt`, or the docs markdown mirror). Do not re-fetch the HTML page if it is a truncated docs shell.
2. Extract tool names, required arguments, and whether each call is read-only. That list is the catalogue. Search results are a sample.
3. If the operation is absent from that catalogue, stop looking for a hidden MCP tool. Say the connector does not expose it, then use the CLI fallback in section 4 when the user asked to mutate a hosted resource.

## 3. Read the grant, then call by exact name

1. Call the account or context tool by the exact public name (`get_fly_context` or the equivalent), even if search never listed it. Read bindings: org slug, resource ids, and scopes. Do not invent a slug. Aliases such as `personal` are often rejected.
2. Call the read tool with the concrete id from that grant. Use `use_mcp_tool` and the returned tool name, not a shortened guess.
3. If the public name was never in search and is not in the vendor catalogue, one exact-name probe is enough. `unknown MCP tool` means it is not on this connector. Do not loop guessed names (`query_metrics`, `get_metrics`, `prometheus_query`).

## 4. Fall back to the vendor CLI for a missing mutation

Use this only after search and the public catalogue both omit the operation, and the user asked to delete, pause, or otherwise change a hosted resource the connector cannot reach.

1. Check whether the vendor CLI is already installed (`which <cli>` or the package manager's bin path). Do not install a CLI, trust a tap, or upgrade it just to find the command.
2. List resources before mutating. Match the target by the id created or named in this conversation, not by a similar name. Leave every other resource untouched.
3. Read the subcommand help. Pass the explicit ref and the non-interactive yes flag the help documents (`--yes` or the equivalent). Do not rely on a prompt; some CLIs still print a confirm line after `--yes`.
4. List again and confirm the target is gone and the others remain. Report only that result.

## 5. Report the snapshot and the gap

1. Return the authorized resource and the live fields you actually read (status, region, host, memory limit, recent events).
2. If the missing operation needs a separate token (Prometheus, billing, logs), say so and name the public endpoint pattern. Do not scrape credentials or call a token helper.
3. A point-in-time memory or host reading is not a time series. Do not present it as CPU, request rate, or error rate.

## Pitfalls

- Repeating `search_mcp_tools` on a 30+ tool server fills the turn with the same write-tool schemas. One bad search plus the public name list beats five searches.
- Context and grant tools are often callable when search omits them. Search is not the full catalogue.
- A signed-in grant only sees its bindings. Do not ask which app to query until that list is empty or does not match the request.
- Write-scoped reads such as machine memory can still be a snapshot. Equal available and limit means no pressure right now, not a usage chart.
- A connector that creates projects does not imply it can delete them. Why: search returns sibling verbs (`delete_feedback`) and hides the gap; the installed vendor CLI is the catalogue for that mutation.
- Deleting by display name is unsafe when the account has an older project with a similar name. Why: the CLI deletes whatever ref you pass, and the action is irreversible.