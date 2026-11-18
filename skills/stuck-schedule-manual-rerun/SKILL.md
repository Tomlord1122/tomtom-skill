---
name: stuck-schedule-manual-rerun
description: >-
  Catch schedules a local app missed while it was closed, and keep a manual rerun for an immediate extra run. Use when next_run_at is already past, an outstanding job blocks advancement, a laptop was off so the cron tick never ran, or the user wants overdue labeled and a Run now action. Do not use for a one-shot that already fired and was disabled, for a job retry endpoint, or for OpenAPI client formatting drift.
metadata:
  cometline:
    origin: self-improvement
tags:
  - scheduler
  - jobs
  - ui
---

# Catch a missed local schedule, and keep a manual rerun

A future-looking label that prints a past duration means the stored next-run timestamp is behind now. On a scheduler that refuses to advance while a previous firing is still open, that timestamp stays stuck until something clears the open job. A display-only wording change does not make the schedule run again.

A local app has a second cause. While the process is down, nobody polls. After startup, a due row is not "still the same occurrence" if its stored next run is older than one poll interval. That missed occurrence must be queued once, even if the previous job is still open. The periodic skip stays only for a firing that is a few seconds late, so an open job is not duplicated while the app is running.

## Steps

1. Find the label and the timestamp it formats. Search the UI for the chip text (`Next:`) and the formatter it calls. Confirm the formatter appends a past suffix such as `ago` whenever the timestamp is less than now. That is the display bug, not proof the clock is wrong.

2. Read the materialize path and the worker start before changing the label. Search for the function that creates jobs from due schedules, and for the loop that calls it on a ticker. Note two separate gaps:
   - The worker waits for the first tick, so a restart does not scan until one poll interval later.
   - Materialize skips a schedule that already has an open job and does not advance `next_run_at`. That skip is correct for a recent firing. It is not correct for a next run that aged past one poll interval while the process was off.

3. Catch the offline miss inside materialize, do not replace the recent-open skip:
   - If an open job exists and `next_run_at + poll_interval` is still at or after now, continue. The same occurrence is still in flight.
   - If an open job exists and `next_run_at` is older than one poll interval, soft-delete outstanding jobs for that schedule (todo, ongoing, blocked, not already deleted), then create one new job. Leave done jobs alone.
   - Create the job before advancing fire state, so a failed create leaves the schedule due.
   - Advance cron from now, or mark a one-shot fired. Do not enqueue one job per missed cron slot. One catch-up run is the occurrence the user expects after a closed laptop.

4. Call that same materialize once at worker start, before creating the ticker. Reuse the function. A second startup-only path will drift from the tick. Log the same failure and count lines the tick already uses.

5. Keep a manual rerun that is separate from the tick. Startup catch-up covers "the machine was off." It does not cover "run this enabled schedule right now."
   - Load the schedule. Reject a disabled one.
   - Clear outstanding jobs, then create the new job before advancing fire state.
   - For cron, compute the next run from now. If the stored next run is still in the future and later than that computed slot, keep the stored slot. One cron step from now can be earlier than a stuck future slot, and moving backward makes the schedule look like it lost time.
   - For a one-shot, mark it fired instead of computing a cron slot.
   - Expose it as its own endpoint, not as a patch of `enabled` or a job retry. Follow the repo's contract path: OpenAPI operation, generated server and client, then the handler. Wire the strict server method or the route will not compile.

6. Change the next-run label only for a past timestamp on an enabled schedule. Replace the past suffix (`3d ago`) with an overdue suffix (`3d overdue`), and drop the "Next:" prefix on that chip. Keep future labels (`1h left`) and the shared relative-time helper unchanged so lease and "updated" chips still say ago.

7. Put a Run now action on the schedule card, disabled while a save is in flight, and confirm before clearing the unfinished run. Reload both the schedule list and the job list after success so the cleared job and the new next-run time appear together.

8. Test the stuck case and the offline case separately.
   - Recent open job: materialize once, call materialize again a few seconds later, and assert count 0. The open job must still block a duplicate.
   - Offline catch-up: materialize once so an open job exists, then set that schedule's `next_run_at` to well before now without changing `cron_expr`. Call materialize at now. Assert one fresh todo job and a future `next_run_at`.
   - Manual rerun: call the rerun endpoint and assert one fresh todo job, `last_run_at` set, and `next_run_at` still in the future. Do not assert `next_run_at` is strictly greater than the pre-rerun value.

## Pitfalls

- Treating every past `next_run_at` as "leave it until the open job finishes" leaves a closed laptop overdue forever. The skip is only for a firing inside one poll interval.
- Clearing every open job on every tick duplicates work while the app is up. Gate the clear on age, not on "has open job."
- Calling materialize a second time in a test right after the first call does not simulate downtime. The first call already advanced `next_run_at` to the next cron slot, so the second call sees nothing due.
- Updating a schedule through the general update method to plant a past `next_run_at` can drop `cron_expr` and turn the row into a one-shot, or recompute `next_run_at` from now. Add a test-only query that sets `next_run_at` and leaves cron alone, then regenerate sqlc. Do not invent a helper the queries package does not have.
- Editing only the formatter leaves the schedule overdue forever. The user still cannot rerun it.
- Replacing the function body of materialize with the rerun body, or the reverse, breaks both. After a signature swap, read the whole function before the next edit.
- A shared relative-time helper that always emits `ago` or `left` is reused by leases and updated-at. Specialize the next-run label instead of changing the helper.
- Compare millisecond timestamps as integers. JSON numbers become float64, and `int64(float64(ms))` can drop the value by a few milliseconds and fail a `<=` check that the schedule did not actually move backward.