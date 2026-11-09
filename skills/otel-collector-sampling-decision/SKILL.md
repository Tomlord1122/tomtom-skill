---
name: otel-collector-sampling-decision
description: Separate OpenTelemetry head sampling, tail sampling, and post-hoc filtering, including mid-trace decisions. Use when the user asks the opposite of tail sampling, whether head and tail are exclusive, or how to drop a trace once a condition is known before the trace finishes.
tags:
  - opentelemetry
  - observability
  - sampling
metadata:
  cometline:
    origin: self-improvement
---

# OTel Collector sampling decisions

Answer from decision timing, not from the word "sampling". Head and tail are when the keep/drop call is made. Filtering is a later rule that deletes already-received data. They stack. A dropped span cannot be recovered by a later processor.

## 1. Check the user's wiki, then the processor README

1. Search the wiki for `tail sampling`, `head sampling`, `tail-based`, and `head-based` before restating a page the user already has.
2. Fetch the primary source, not a blog summary: `https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector-contrib/main/processor/tailsamplingprocessor/README.md`. HTML GitHub pages truncate the practical-example and FAQ sections; the raw README is the one that names early-decision knobs.
3. Cross-check concepts at `https://opentelemetry.io/docs/concepts/sampling/index.md`. Official docs list only `probabilisticsamplerprocessor` and `tailsamplingprocessor` as Collector samplers. Do not invent a third sampler from a blog.

## 2. Map the question onto the mechanism

1. "What is the opposite of tail sampling?" → **head sampling**. The decision is at root-span start, written into the W3C `traceparent` sampled flag. Downstream spans follow it. It is cheap and blind to later errors and latency.
2. "Can I filter after tail sampling, or must I pick one?" → stack them. Typical intent is SDK head sampling to cut volume, Collector `tail_sampling` to keep errors and slow traces, then `filter` (OTTL) to drop leftover noise. `attributes` / `transform` rewrite fields; they do not decide keep/drop.
3. Place context-dependent processors **before** `tail_sampling`. It regroups spans by `trace_id` and emits new batches, so later processors lose the original pipeline context (`k8sattributes` is the documented example). Put `filter` after tail sampling only when the rule should run on traces that already survived sampling.
4. `filter` is span-scoped. It cannot see whether some other span in the trace errored. "Keep the whole trace if any span is an error" is a tail-sampling policy, not a filter.
5. Official terminology: sampled means kept and exported. Filtering is not sampling; a filtered set is not a representative sample of the population.

## 3. Mid-trace "we already know" is not tail sampling

Default tail sampling waits. `decision_wait` (default 30s) is a timer, not "release when the condition appears". `decision_wait_after_root_received` only accelerates that timer after the root arrives. `sample_on_first_match` stops evaluating later policies; it does not flush the trace early. Do not recommend tail sampling when the user can decide before the trace ends — it buffers spans for nothing.

Pick by what the condition is attached to:

1. **Condition is on the span that just arrived** (route, attribute, status): a `filter` processor at the front of the pipeline. Matching spans drop on arrival. Sibling spans in the same trace stay unless they also match.
2. **From this service onward, stop creating spans**: the SDK sampler runs on every `StartSpan`. That service can return Drop for later children. Spans already exported, and spans other services already started, are not recalled. Downstream services honor the sampled flag already in `traceparent`; they do not learn a mid-trace change of mind.
3. **Need a different export path, not a whole-trace cancel**: a `routing` connector splits pipelines. It is still span-scoped. There is no standard Collector mid-trace cancel.
4. **Decision needs the outcome** (any-span error, total latency, span count): tail sampling, with every span of that `trace_id` on the same collector (load-balancing exporter in front when scaled).

## 4. If you do use tail sampling, match the strategy to the policy

- `sampling_strategy: trace-complete` (default) evaluates accumulated spans on the timer. Required for stateful policies (latency, span count, rate/bytes limits).
- `sampling_strategy: span-ingest` evaluates each incoming batch immediately. Terminal Sampled/Dropped outcomes finalize at ingest; non-terminal traces stay pending and are finalized as not sampled on cleanup **without** re-evaluating the whole trace. It rejects stateful policies. Use it only when a single batch can produce a terminal decision.
- Policy combination: a Drop vote wins; a Sample vote keeps the trace unless something dropped it; otherwise the trace is not sampled. Prefer `drop` and `not` over deprecated `invert_match`.
- Do not combine `sample_on_first_match` with the `processor.tailsamplingprocessor.usetracestate` feature gate. First-match can skip a later policy that would have reported a less strict threshold and corrupt adjusted counts.
- Probabilistic cut without other tail policies: use `probabilisticsamplerprocessor`. It hashes the trace ID and does not need to wait. Add a probabilistic **policy** only when tail sampling is already in the pipeline, so other policies can still keep the trace.
- Size `num_traces` and `decision_wait` together. A short wait or a small buffer drops traces before a decision (`sampling_trace_dropped_too_early`). Decision caches must outlive `num_traces` or late spans are re-decided as a new trace.

## Pitfalls

- Blog posts often say tail sampling "waits until the trace is complete" and stop there. The README's `span-ingest`, `sample_on_first_match`, and `decision_wait_after_root_received` are easy to miss and easy to over-claim. Read the raw README before saying a knob releases early.
- `sample_on_first_match` is not an early release. Treating it as one sends the user to the wrong component.
- Head sampling that already dropped the trace cannot be undone by collector tail sampling or filter. Say that explicitly when stacking layers.
- A missing Collector pipeline compiles and silently drops that signal. Confirm the processor is actually in the traces pipeline.
- HTML fetches of the GitHub README truncate before Scaling, FAQ, and late-span behavior. If the fetch ends mid-section, fetch the raw URL again with a higher `max_chars` instead of filling the gap from a secondary blog.