---
name: electron-idle-cost-audit
description: Audit an existing Electron app for performance by measuring idle Chromium and renderer cost before suggesting caches. Use when the user asks how to make an Electron or desktop shell faster, reduce RAM, or improve startup, and the repo already has windows, a sidecar, and a renderer. Do not use for designing a new Electron app, IPC security, or packaging.
metadata:
  cometline:
    origin: self-improvement
---

# Electron idle-cost audit

Recommend changes that remove cost the app already pays while idle. Do not recite generic Electron tips, and do not re-recommend optimizations the code already has.

## 1. Bound the advice

Load `electron-architect` only to keep security constraints: no `nodeIntegration`, no raw `ipcRenderer`, validated IPC. Its skill has no idle-cost procedure. Do not copy its scaffold, window matrix, or packaging examples into a performance answer.

Read `@runtime/wiki/index.md` first. Open at most three pages that actually describe the desktop shell, frontend, or architecture. A catalog link is not a file. If `read_file` says the page is missing, stop citing it and audit source.

## 2. Find the shell, then the startup sequence

Search the Electron tree, not the whole monorepo first:

- `glob` `**/main.ts` and `**/app.ts` under the Electron package.
- Read the window factory (`BrowserWindow` constructors) and the `app.whenReady` composition root.
- Note which windows are created at startup, delayed, or on first show.

If workspace-root `grep` fails with `fork/exec .../rg: not a directory`, retry with `path` set to the Electron package or the renderer package. A scoped search works when the root search cannot exec `rg`. Do not treat search as unavailable, and do not switch to a full-repo walk.

Useful searches, each scoped:

- `BrowserWindow`, `webPreferences`, `backgroundThrottling`, `webviewTag`, `paintWhenInitiallyHidden`
- `whenReady`, `prepareMiniWindow`, `spawn(`
- renderer `setInterval`, `EventSource`, `text/event-stream`, `getReader`
- markdown/highlight and list virtualization (`content-visibility`, virtual window helpers)

## 3. Inventory idle cost before hot paths

Check these in order. Skip a recommendation when the code already does it, and name that existing mitigation.

1. **Startup blockers.** Work `await`ed in `whenReady` before the first `BrowserWindow` delays first paint even if it does not create a window. Localhost bridges and gateway sync can move to after `ready-to-show` unless the first frame needs them.
2. **Windows that stay alive.** Count main, prewarmed, settings, and offscreen windows. A window created on first use is not an idle cost. A hidden prewarm is.
3. **Hidden-renderer flags.** `backgroundThrottling: false`, `paintWhenInitiallyHidden`, `transparent`, and `vibrancy` keep GPU and timer work alive after hide. Prefer toggling throttling off only while the prewarm must stay instantly showable, then back on after hide.
4. **Per-window polls.** A `setInterval` in a shared layout runs once per `BrowserWindow` that mounts it. A 1s health poll on three windows is three request loops. If a long-lived SSE or event stream already exists, ready-state polling should back off or stop. When the user wants the poll kept, follow section 6 instead of deleting it.
5. **Capability flags on every shell.** `webviewTag: true` on every window pays guest-view cost even when no panel is open. Attach it only for the window that hosts the guest, or use a separate window created on demand.
6. **Hot paths already optimized.** If streaming markdown is throttled, the thread is virtualized, or an offscreen search window is created on first query, say so and do not recommend those again.
7. **Heavy renderer init.** A highlighter or grammar bundle that loads every language on first code block is startup/jank cost. Lazy-load uncommon languages. Do not recommend another full re-render pipeline if the last incomplete block can be the only one re-highlighted.

Before ranking a cheap localhost poll as the cause of chat jank or slow startup, read the handler. A JSON `{"status":"ok"}` with no database and a logger that already returns early on that path is idle wakeups, not the felt stall. Say so, and point at markdown/highlight and vibrancy first.

## 4. Rank, then refuse low-value rewrites

Order suggestions by idle cost times number of live windows times size of the diff. The first item should be a small change with a measurable idle effect, usually a poll or a hidden-window flag.

Do not recommend:

- Removing a commented prewarm or `backgroundThrottling: false` without naming the hitch that comment exists to avoid. Suggest a hide/show toggle instead.
- Moving a working sidecar from `spawn` plus a health gate to `utilityProcess` as a performance project. Process-model moves have unclear RAM wins and high regression risk.
- Disabling hardware acceleration on a transparent or vibrancy window. Those windows composite on the GPU; turning acceleration off usually makes them slower.
- Adding a cache, virtualizer, or protocol `codeCache` that the code already has.

## 5. How to answer

Lead with what is already done, then the remaining idle costs, each tied to a file and a flag or timer. End with what not to do. If the wiki page was missing, say the judgment came from source.

## 6. Back off a health poll without slowing cold start

Use this when a shared layout starts a fixed health `setInterval` and the user wants it slower once the sidecar is up. Do not replace the poll with SSE unless that stream already covers process death and the product accepts losing the explicit health gate.

1. Read the connection store and its tests before editing. Note the grace budget (failed attempts before startup error), the "already ready then one failure is an outage" rule, and that `check()` may be called by hand.
2. Read the health handler and access log. Confirm the endpoint is a static ok body and successful hits are not logged. If it hits a database or writes a log line, slowing the timer is not the fix.
3. Replace the fixed interval with a self-rescheduling timeout. Keep a `polling` flag so `stopPolling` clears the pending timeout and refuses the next schedule. Keep a `checkInFlight` flag so a slow fetch cannot overlap the next tick.
4. Choose the next delay from status after the check returns:
   - `connecting` or `error`: stay on the fast cadence (1s). Cold start and reconnect still exhaust the grace budget in the same wall time.
   - `ready`: steady cadence (10s). Schedule that delay only after a successful check, not on a counter of consecutive successes that can drift from status.
5. `startPolling` runs one check immediately, then schedules. A second `startPolling` while `polling` is true returns. Manual `check()` does not schedule and does not clear the timer.
6. Run the store test from the Electron package directory, not the monorepo root. `pnpm exec vitest` at the root fails with `Command "vitest" not found` even when the package has it. `cd <electron-package> && pnpm exec vitest run <test-file>`.

Add two timer tests with `vi.useFakeTimers()` and `vi.advanceTimersByTimeAsync`:

- First scheduled check fails, status stays connecting, the next check is at 1s and becomes ready, then no fetch until 10s.
- A ready connection's next check fails, status becomes error immediately, and the following check is 1s later rather than another 10s.

Do not advance only `0` and assume the interval fired. The first check is the direct call; the next boundary is the timeout that was scheduled from the status that call left behind.

## Pitfalls

- **Root `grep` can fail while scoped `grep` works.** `fork/exec .../rg: not a directory` is an environment exec failure, not evidence the symbol is absent. Retry with `path` set to the package that owns the file.
- **Wiki index entries are not pages.** Citing a missing `@runtime/wiki/...` path invents architecture. Fall back to source.
- **Security skills pull generic IPC samples.** Performance advice that is not grounded in this repo's window factory and `whenReady` path is noise.
- **Shared layouts multiply timers.** A poll that looks cheap in one file runs in every BrowserWindow that mounts that layout, including hidden prewarms.
- **Servers are not windows.** A bridge that only `listen`s at startup still blocks first paint if it is `await`ed before `createMainWindow`. A `BrowserWindow` created inside the request handler is not idle cost.
- **Intentional latency comments are constraints.** A prewarm delay and disabled background throttling are often a measured trade for shortcut feel. Recommend returning the cost after hide, not deleting the trade.
- **A fixed `setInterval` cannot back off.** The next delay depends on the result of the check that just finished. An interval started at 1s keeps firing at 1s after ready, and one started at 10s makes cold-start grace 10x slower.
- **Do not treat a trivial health loop as chat jank.** Three localhost ok-responses a second are wakeups and idle power, usually well under 1% CPU. Ranking them above markdown, Shiki, or vibrancy sends the next change at the wrong layer.
- **Package scripts are not on the workspace root.** A missing `vitest` from the monorepo root is the wrong working directory, not a broken toolchain. Re-run inside the package that declares the script.