---
name: govulncheck-ci-failure
description: >-
  Diagnose a failed govulncheck GitHub Actions job, bump the called module to the fixed version, and re-scan with the Go toolchain the job actually used. Use when a vulnerability check fails, the Actions page says sign in to view logs, or a local govulncheck run reports standard-library findings the CI job did not. Do not use for OpenAPI generated-client drift, commit-message style, or dispatching a release.
tags:
  - ci
  - go
  - govulncheck
metadata:
  cometline:
    origin: self-improvement
---

# Clear a govulncheck Actions failure

The job fails because govulncheck found a vulnerability the module actually calls. The public Actions page does not contain the finding, and a newer Go on the laptop scans a different standard library than CI. Match the job's toolchain before deciding the bump worked.

## 1. Take the ids from the URL, not the HTML

`actions/runs/<run-id>/job/<job-id>` is the source of both ids. `web_fetch` of that URL returns the signed-out shell ("Sign in to view logs") plus annotations. Annotations name the failing step and sometimes the call sites. They do not name the vuln id, the module version, or the fixed version. Do not stop there.

## 2. Filter the failed log

The tail of `--log-failed` is runner cleanup (credential config unset, "Cleaning up orphan processes"), not the error. Filter before reading.

```bash
gh run view <run-id> --repo <owner>/<repo> --job <job-id> --log-failed 2>&1 \
  | rg -n "Vulnerability #|GO-|Fixed in:|Found in:|govulncheck|##\[error\]"
```

If the tool truncates the stream, keep this filter. Do not re-read the cleanup tail.

The useful block names the module, the version found, the fixed version, and the call trace (`##[error]` lines). That called-symbol trace is why the job exited non-zero. A later note that other vulns exist in required modules but are not called did not fail this job.

## 3. Bump only that module

Run from the directory that contains the module's `go.mod`, not the git root.

```bash
cd <module> && go get <module-path>@<fixed> && go mod tidy
```

Confirm `go.mod` and `go.sum` changed only for that module. Run the package tests that cover the call sites in the trace before committing.

## 4. Re-scan with the job's Go and the job's govulncheck pin

Read the Go version from the job log (setup-go cache key `go-1.x.y`, or the toolchain the `go-version-file` step resolved). Do not use `go version` on the laptop. Read the govulncheck pin from the workflow or Makefile (`go run golang.org/x/vuln/cmd/govulncheck@vX.Y.Z`). A different scanner version can disagree with CI.

```bash
cd <module> && GOTOOLCHAIN=go1.x.y go run golang.org/x/vuln/cmd/govulncheck@vX.Y.Z ./...
```

A pass is exit 0 with "No vulnerabilities found" / "affected by 0". An extra line that a required module has a vuln the code does not call is still a pass for this check. The original id must be absent.

## Pitfalls

- govulncheck scans the standard library of the toolchain that executes it. A newer laptop Go reports findings in `crypto/x509`, `net/http`, or `mime` at that newer version. Those are not the Actions failure when the job log shows an older `go-1.x.y`. Force `GOTOOLCHAIN` to the job's version. Do not bump the module's `toolchain` line to silence them.
- The `toolchain` line in `go.mod` is a minimum, not a pin. `go run` without `GOTOOLCHAIN` keeps the installed Go when it is newer, so the laptop scan and the Actions scan diverge even when `go.mod` already names the CI version.
- `gh run view --log-failed | tail` is the end of the job, not the finding. Filter for `Vulnerability #`, `Fixed in:`, and `##[error]` first.
- govulncheck exit 3 means called vulnerabilities. Exit 0 plus an uncalled-module note is success. Do not bump unrelated modules to clear that note unless a later job fails on it.
- `go get`, `go test`, and `govulncheck` at the git root fail with `go.mod file not found` when the module is one directory down. Change the directory, not the flags.
- Clearing this job does not include dispatching a release workflow. Pushing the default branch is a separate request.