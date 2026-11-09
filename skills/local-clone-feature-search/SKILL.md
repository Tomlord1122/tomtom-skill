---
name: local-clone-feature-search
description: Find how a feature is implemented in a local open-source checkout when the first keyword hit is the wrong subsystem. Use when the user points at a cloned repo and asks how it defers, loads, searches, or registers tools, plugins, or MCP, and a broad grep returns background-task or plugin-skill noise. Also use when comparing how hosts advertise MCP Apps or another extension, so an initialize string is not treated as a renderer. Do not use for GitNexus graph queries, vendor HTML docs, or a checkout that is not on disk.
tags:
  - research
  - codebase
metadata:
  cometline:
    origin: self-improvement
---

# Search a local clone past colliding names

A user-cloned repo is the source of truth for "how do they do this". GitNexus and the built-in `grep` tool are optional. Neither one is the implementation.

## 1. Confirm the tree, then search with shell rg

1. `list_dir` the path the user gave. Do not assume `packages/<product>/src` exists. List the directory and search the packages that actually exist.
2. Prefer `run_command` with `rg -n -l` over the built-in `grep` tool. The built-in tool can fail with `fork/exec .../rg: no such file or directory` while shell `rg` works.
3. Scope the first search to source, not docs: `--glob '!**/node_modules/**' --glob '!**/dist/**' --glob '!**/target/**' -g '!*.md' -g '!*.mdx'`.
4. If the guessed directory is missing, `ls` the parent and rerun against the real source root. Do not keep searching the missing path.
5. Drop generated protocol dumps from the first pass (`schema/json`, `schema/typescript`, `sdk/**/generated`). Open them only after the Rust or Go writer that emits the field is found.

## 2. Discard the colliding subsystem

The same words name more than one feature. Treat a hit as the wrong subsystem when the surrounding identifiers are about UI chrome, background work, plugin instructions, or a chart viewer rather than the catalog or protocol the model sees.

| Query | Wrong hit | Why it is wrong | Next query |
| --- | --- | --- | --- |
| `deferred`, `defer_loading` | `bg_deferred_tools`, background admission | Defers a running call or a wake, not schema loading | `ToolSearchIndex`, `search_snapshot`, `search_tool` |
| `ToolSearch` | A skill file that tells the model to call `ToolSearch` | Plugin copy, not the host registry | `codemode`, `CodeMode`, tool registration options |
| `tool_search` | Telemetry counters, permission allowlists | Names the feature without implementing it | The type that owns `search_snapshot` and its callers |
| `iframe`, `srcdoc`, `mcp-app` | An inline chart or visualization viewer | Renders HTML the host authored, not an MCP UI resource | `io.modelcontextprotocol/ui`, `resourceUri`, `McpAppUi` |

Stop following a file once its comments say it drops streaming updates, parks a task, or documents a prompt. The loading path lives next to the tool registry, index, or catalog.

## 3. Read the interface, then the caller that hides schemas

1. Read the search or catalog type first (`ToolSearchIndex`, a catalog summarizer). Note whether a hit already carries the full input schema.
2. Find the concrete index and the meta-tool that runs it. In a Rust tree that is often `session/tool_index.rs` plus `implementations/search_tool` and `implementations/use_tool`.
3. Find the registration flag that keeps a tool off the native provider list. Search `codemode: false` and the registry comment that says the default is on. Read that short architecture note before the runtime.
4. Read only the dispatch function that turns a search hit into a call (`use_tool`, a sandbox `tools.*` call). Do not read coordinator, pager, or tracker tests unless the question is about background tasks.

## 4. Separate advertising an extension from hosting it

When the question is "how does this host do MCP Apps" (or any negotiated extension), split the search into three layers and report each as present or absent. A string match on the extension id only proves layer 1.

1. **Advertise.** Find the initialize capability map. Record the extension id and the exact settings object (`mimeTypes`, and whether the value is `text/html` or `text/html;profile=mcp-app`). A unit test of a helper may use a wider MIME than the client that actually connects. Prefer the client initializer.
2. **Discover.** Find the function that reads tool `_meta`. Record every key it accepts, in order. MCP Apps hosts have used `_meta.ui.resourceUri`, the flat key `ui/resourceUri`, and `openai/outputTemplate`. Also record visibility: a `ui.visibility` array that omits `"model"` can keep a tool off the model catalog while still listing it for the app. Note whether the notification carries `sessionId`.
3. **Host.** Search for `ui/initialize`, `postMessage`, `ReadResource` / `resources/read` of a `ui://` URI, and an iframe whose `src` or `srcdoc` comes from that resource. If those are absent, say the checkout discovers UI and does not host it. Do not infer a sandbox, CSP, or method list from the extension string.

Read the protocol struct the host emits (`McpAppUi`: `resourceUri`, `preferredModelDisplayMode`) before inventing a parallel event name. A legacy field kept beside the new struct is compatibility, not a second design.

## 5. Report the mechanism, not the keyword

State which of these the host actually does:

- Search index plus one stable dispatch tool, with schemas returned in the search result and native tools left on the provider list.
- A code sandbox whose catalog is budgeted, with non-native tools callable only from inside that runtime.
- A prompt instruction that assumes a hosted `ToolSearch` the repo does not implement.
- Extension advertised and metadata preserved, with rendering left to another process.
- Full host: resource fetch, sandbox, and guest bridge in this tree.

Do not say two hosts share an approach because both strings contain `deferred`, `search`, or `io.modelcontextprotocol/ui`. Name the files you read. If the local tree has no implementation, say so instead of inferring it from a skill or a blog.