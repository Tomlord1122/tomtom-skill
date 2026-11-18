---
name: local-runtime-remote-companion
description: Classify Cometline remote access before designing it. Use when the user wants a phone, browser, iOS client, hosted database, remote CometMind, a UI that switches runtimes, or a cloud deploy of the agent. If the desktop must stay the only brain, follow the companion rules. If the UI should switch between complete local and remote instances, do not force those rules. Do not use for a product that is already vendor cloud-chat plus optional local connectors.
metadata:
  cometline:
    origin: self-improvement
---

# Classify remote access before designing

A remote face for one local brain is not the same product as a UI that switches between full runtime instances. Classify first. Do not apply companion constraints to the second shape.

## Classify before designing

1. Name who thinks, who executes tools, and where the live source of truth sits.
2. Map the request onto one shape:
   - **Remote companion:** the desktop process keeps running. Phone or browser reads history and sends turns. Files, shell, MCP, and keys stay on that machine. If the machine sleeps, remote clients can only read already mirrored history.
   - **Local server plus thin client:** TUI, desktop, and IDE plugins talk to a server on the same machine. That is multi-client, not an internet companion, unless the user deliberately exposes the server.
   - **Switchable full runtime:** the UI is a shell with connection profiles. Each profile is a complete CometMind instance (agent loop, tools, and its own records). Local SQLite and a cloud Postgres or RDS are different instances, not a mirror of one brain. A later iOS or browser client uses the same HTTP/SSE contract against the remote instance. The laptop can be off.
   - **Cloud chat plus local connectors:** conversation and model live in the vendor cloud. The desktop app only attaches files or tools. Do not call this a remote companion or a switchable CometMind runtime.
3. If the product already has an inbound gateway (Discord, Slack, or similar) that routes messages into the same local runtime, a new client of that same brain is another adapter. Do not invent a second architecture for that case.
4. If the user wants the UI to connect to a deployed CometMind that is itself the brain, stop here and follow "Switchable full runtime". Do not keep the desktop as the only brain.

## Verify the contract before designing

Do this for either shape. Do not assume a runtime split already exists.

1. `read_file` `@runtime/wiki/index.md`. If a Cometline architecture page is listed, read that page only.
2. Search the repo for the client base URL, the serve bind address, and `sqlite.Open`. Read `cometmind/internal/runtime/runtime.go` and `cometmind/cmd/serve.go`.
3. Expect, until the code changes: the UI hard-codes `http://127.0.0.1:7700`, `serve` listens only on `127.0.0.1`, there is no remote auth, and one `Runtime` opens SQLite and owns the loop, tools, MCP, jobs, and memory.
4. Ignore `ServerRuntimeStatus` in the MCP package. That type is MCP server health, not an agent/server split.
5. Search memories for an earlier companion boundary. If this request is the switchable shape, say so. Do not let the old "phone is only a face" boundary overwrite a request for a cloud brain.

## Switchable full runtime

Use this when one device should switch between a local sidecar and a remote CometMind, or when iOS should attach to the cloud instance while the laptop is off.

1. Split only what switching needs:
   - **Agent runtime:** the loop, tools, MCP, files, and shell on the machine where that process runs.
   - **Server runtime:** sessions, memory, jobs, inbox, and the HTTP/SSE API. The UI talks only to this API, never to the database.
2. Keep three profiles distinct: local (this machine thinks, tools, and SQLite), cloud instance (that process thinks, its workspace volume, its database), and companion (not this shape; the cloud is only a mailbox).
3. Order the work. Do not start with the chart.
   1. Persistence interface. Keep SQLite as the local store so a remote instance can use Postgres or RDS without rewriting the loop.
   2. Non-loopback bind only when a remote profile is explicit. Require TLS and a bearer token or device credential. Leave the local default on loopback with no login.
   3. UI connection profile: name, base URL, credential. Show which instance is active and where its tools run.
   4. Container image and Helm for one CometMind instance, its database, an API credential secret, and a workspace volume.
4. Many clients may watch one run. The event hub already fans out. Only one owner may run the agent loop for a session.
5. Switching profiles switches instances. Do not sync or merge histories in the first version.
6. First remote clients carry chat, streaming, jobs, and inbox. Do not put a terminal or a file tree on the phone.
7. A container or Helm task whose user is a Discord bot is packaging. Link it. Do not treat it as the UI switch, and do not publish the current unauthenticated API.

## Do not move the brain

Apply this section only after classification says remote companion.

- Keep the local database as the live source of truth. A hosted Postgres or Supabase project is a mailbox and mirror, not the agent loop.
- Leave filesystem paths, shell output, provider keys, embeddings, and media blobs on the machine that executes tools.
- Allow only one owner for an in-flight run. Do not start with CRDT sync between the phone and the desktop.
- When the brain is offline, queue a draft. Do not pretend the cloud can edit the local workspace.

## Check the hosted project before writing schema

Apply this when the companion shape uses a hosted project as a mailbox. Do not use these tables as the source of truth for a switchable cloud instance.

1. List the user's projects and tables. A project named after a personal site is not an empty app database.
2. Read table names. Website tables such as blogs, pages, and visits mean the project is already a product. Do not add agent sessions there.
3. If a table has RLS disabled, tell the user. Do not enable RLS yourself; without policies that locks the existing app out, and with the wrong policies it exposes rows.
4. Create a separate project only after the user agrees. The service role stays on the desktop sidecar. The phone gets the anon key plus RLS.

## Build the companion client as a shell first

Apply this only to a phone or browser face for the local brain.

1. Read the desktop routes and footer so the phone shows only surfaces a remote face can carry: sessions, chat, jobs, inbox, and read-only skills, usage, or gallery.
2. Use mock data. Do not wire the phone to the website project or to the local API on `127.0.0.1`.
3. Show brain awake versus asleep in the UI. Sending while asleep queues the draft; sending while awake appends a turn that the local runtime would claim.
4. If the machine has only Command Line Tools, `xcodebuild` fails. Write Swift sources plus an XcodeGen `project.yml` and say Xcode is required to run it. Do not claim the app was built.

## Pitfalls

- **Hosting the database is not hosting the agent.** The phone still cannot read the user's repo or run MCP unless the agent process is on that remote instance. Why: tools are bound to the process and its workspace, not to the database.
- **A switchable cloud instance is not a companion mailbox.** Do not reuse pending-turn or brain-status tables as the cloud source of truth. Why: those tables are a queue for a sleeping desktop, not sessions, memory, and jobs for a brain that runs in the cloud.
- **Switching instances is not syncing them.** Keep local history and cloud history separate until a later design names a single owner for an in-flight run. Why: two brains means two records; merging them is a different product.
- **Packaging the binary is not exposing the API.** A chart that publishes the current serve port is unsafe. Why: serve binds loopback and has no remote auth.
- **An existing hosted project is not the app's project.** Website tables and a missing RLS policy make reuse unsafe. Why: one anon key would mix products and expose rows.
- **A gateway already proves the companion shape.** Reuse its inbound-turn idea for another face of the same local brain. Why: the difference is transport and UI, not who thinks.
- **Do not mirror full tool arguments or shell output** until there is a redaction pass. Why: those fields contain paths, tokens, and private file contents.
- **`ServerRuntimeStatus` is the wrong split.** Why: it reports MCP server health, not an agent runtime versus a server runtime.