---
name: mcp-oauth-missing-refresh
description: Diagnose an MCP connector that shows signed in but reconnect fails because the stored grant has no refresh token, then fix the login scope builder rather than the connector catalog. Also use when every enabled MCP server fails together with the same protocol error, or when the user asks whether a named connector can refresh by itself, or whether a scope-merge fix covers every MCP. Do not use for a missing binary, an unsigned-in server, or starting a new browser OAuth flow from the agent.
tags:
  - mcp
  - oauth
metadata:
  cometline:
    origin: self-improvement
---

# MCP OAuth missing refresh token

A connector can look signed in while refresh is impossible. `signed_in` only means a non-empty access token file exists. Refresh runs only when that file also has a refresh token. Reconnect cannot invent one.

A later question about a different connector is not the same failure. If that connector already has a refresh token and client info, prove the client is already rotating it. Do not replay the missing-scope fix, and do not claim every connector is covered.

A whole fleet showing the same `protocol` error is also not this bug. Classify that first.

## 0. Same error on every server is a shared handshake stall

Use this when `list_mcp_servers` shows every enabled server as `status=error`, `tools=0`, `error_code=protocol`, and the same hint that the connection could not complete. OAuth and no-auth servers failing together is the tell. A missing refresh token cannot explain a server that has no OAuth grant.

1. List servers. Record `oauth` and `error_code` for each. Settings live at `cometmind.mcp`, not `mcp`.
2. Redact token files as in step 3, but only to classify. If every OAuth server already has a non-empty `refresh_token` and a client file, stop. Do not fetch protected-resource metadata, do not edit the login scope builder, and do not tell the user to Connect with OAuth again.
3. Reconnect once, using the server id (`connector-…`), and start with the no-auth server if one exists. A no-auth server that returns `status=connected` with a non-zero tool count proves the client handshake works and the failure was not a dead token.
4. Reconnect the remaining servers one id at a time. Stop a server that returns `oauth token missing refresh_token` and continue with step 1 of the missing-refresh path for that id only. A token-endpoint HTTP failure, `invalid_grant`, or handshake timeout on one id is that server, not the fleet.
5. If reconnect restores `connected` and a tool count, the session startup handshake stalled and the status stayed on `protocol`. Say that. Do not claim tokens were dropped, and do not paste token values. Length and presence are enough.
6. If reconnect fails the same way on every id, including no-auth, this skill does not cover the cause. Report the shared error and stop. Do not invent a catalog or scope fix.

## 1. Read the reconnect error before retrying

1. List MCP servers. Note `oauth` and `error_code`. `oauth=signed_in` plus `error_code=protocol` is not a socket failure.
2. Reconnect once with the server id (`connector-…`, not the display name).
3. If the transport says `oauth token missing refresh_token`, stop reconnecting. Another handshake hits the same guard.
4. If the error is a token-endpoint HTTP failure, an invalid_grant, or a handshake timeout, this skill does not apply. Those mean a refresh was attempted.

## 2. Confirm the client refuses before calling the token endpoint

In the MCP OAuth token source, refresh loads the stored token, then returns `oauth token missing refresh_token` when `RefreshToken` is empty. That happens before `TokenSource.Token()` posts to the token URL.

Reconnect and 401 retry both call that path (`ForceRefresh` or `Token()`). A wired refresh implementation does not help if the seed has no refresh token.

`OAuthConnected` is true whenever `access_token` is non-empty. Do not treat that flag, or a future `expiry`, as proof the access token still works or can be renewed.

## 3. Inspect stored files without printing secrets

Credentials live in `~/.cometmind/mcp-oauth/`. Read them with a script that prints only structure:

- `{serverID}.json`: key names, whether `access_token` and `refresh_token` are non-empty, their lengths, `token_type`, `expiry`, `expires_in`, and the file mtime. Never print token values.
- `{serverID}.client.json`: authorization and token endpoints, scopes, resource, server URL, auth style, and the file mtime. Redact `clientSecret` and any key whose name contains secret, token, password, or key (keep endpoint and auth-style fields).

Interpret the pair:

- No token file: not signed in. This skill does not apply.
- Token file, no client file: refresh is not wired; the handler serves a static token. Re-auth is still required for a refreshing grant, but the cause is missing client info, not an omitted scope.
- Client file present, token file has access token and empty refresh token: refresh is wired and correctly refuses. Continue to step 4.
- Both refresh token and client info present: the missing-scope bug is not this connector. Continue to step 8. Do not POST a refresh just to prove the path works.

## 4. Compare the two metadata documents

The login path requests explicit settings scopes when set. When those are empty, resource scopes come from protected-resource metadata (`scopes_supported`). `offline_access` is not a resource scope. It lives on authorization-server metadata. Dynamic client registration may still advertise the `refresh_token` grant type; that does not put a refresh token in the token response.

Fetch both public documents (do not send the stored access token):

- Protected resource: `{origin}/.well-known/oauth-protected-resource` (and the path-scoped variant if the server uses one).
- Authorization server: the issuer from that document, then `{issuer}/.well-known/oauth-authorization-server`.

The gap is confirmed when all of these hold:

- Saved scopes match the resource metadata (often only resource scopes such as `space:read` / `space:write`).
- Authorization-server `scopes_supported` also includes `offline_access` (or another offline/refresh scope the provider documents).
- Authorization-server `grant_types_supported` includes `refresh_token`.
- Saved token has no `refresh_token`. A short `expires_in` (hours or a couple of days) fits a grant that was never issued a refresh token.

Provider-login code that requests `offline_access` for a model vendor is a different store. Do not cite it as evidence that MCP login requested that scope.

## 5. Decide which repo can actually change the authorize request

Do not edit the connector catalog first. Confirm the install path before proposing a catalog field.

1. Read the connector JSON and the catalog entry. A mode with only `url`, `auth`, and `source` has no scope field. Adding one there does nothing until install and login both read it.
2. Read the installer that turns a catalog connector into an MCP server config (search `connectorServerConfig` or the equivalent). If it writes id, name, url, and transport only, settings `oauth.scopes` stay empty even after a catalog change.
3. Read the interactive login builder (`PerformInteractiveOAuth` / `oauth_flow.go`). Explicit settings scopes win over protected-resource scopes. An empty settings list is the normal catalog install, not a missing connector file.
4. Confirm the SDK type. `oauthex.AuthServerMeta.ScopesSupported` is `scopes_supported` on the authorization server. That is the list that may contain `offline_access`. Protected-resource `ScopesSupported` is a different document.

Change only the MCP client that builds the authorize URL. One scope merge covers every connector on that path. A per-connector catalog edit is the wrong repo, and a second UI/runtime change is required before a new catalog field would be honored.

## 6. Merge scopes in the login builder

Add a pure helper and call it where the authorize config is built, after both metadata documents exist:

```go
scopes := resolveOAuthScopes(opts.Scopes, prm.ScopesSupported, asm.ScopesSupported)
```

Rules:

- Non-empty explicit settings scopes stay the resource-scope list. Do not replace them with protected-resource scopes.
- Empty explicit scopes copy protected-resource `scopes_supported`.
- Append `offline_access` only when authorization-server `scopes_supported` contains it and the list does not already have it.
- Copy the base slice before appending so the metadata slices are not mutated.
- Persist the merged list on the saved client info. Headless refresh must reuse the scopes that were actually authorized.
- Do not invent `offline_access` when the authorization server does not advertise it. A grant-type list that includes `refresh_token` is not enough.
- Do not add `access_type=offline` (or another provider-specific authorize parameter) unless that provider's docs require it and the metadata path above does not. A scope merge does not cover servers that issue refresh tokens only through a non-scope parameter.

Comment the options field so a later reader does not treat settings scopes as the full authorize list.

Unit-test the helper, not a live token exchange:

- empty explicit + resource `space:read`/`space:write` + auth-server `offline_access` → resource scopes plus `offline_access`
- explicit resource scopes are kept, and `offline_access` is still appended when advertised
- auth-server scopes without `offline_access` leave the resource list unchanged
- already-present `offline_access` is not duplicated

Run the package tests from the Go module root (`go test ./internal/mcp/ -count=1 -run TestResolveOAuthScopes`). A shell whose cwd is the workspace or a parent repo fails with `go.mod file not found`; `cd` to the module that contains `go.mod`, or pass that directory. Do not treat that error as a broken toolchain.

## 7. Tell the user what will and will not fix it

- Reconnect, restart, and "the client should refresh" will not create a refresh token.
- Signing in again with the same scope list will store another access-only token.
- Editing the connector JSON or catalog, then reinstalling, will not add `offline_access` while the installer omits scopes and login reads only resource metadata.
- The agent reconnect tool must not start the browser flow. Interactive login is the desktop Connect with OAuth action.
- After the login builder is fixed and the new binary is running, the user must Connect with OAuth again. Confirm the new token file has a non-empty `refresh_token` before calling reconnect. The old access-only file cannot be patched.
- Do not paste access or refresh tokens into chat, issues, or logs. Length and presence are enough.
- A fleet that reconnects to `connected` with tool counts was a stalled handshake. Do not send that user through Connect with OAuth.

## 8. Prove an already-refreshing connector without rotating it

Use this when the user names a connector that is still connected, or asks whether "most" MCP servers can refresh after the scope merge.

1. Redact the token and client files as in step 3. Record both mtimes.
2. A refresh already happened when the token file is newer than the client file, `refresh_token` is non-empty, and `expiry` is about `expires_in` after the token-file mtime. The client file stays at the original login; only the token file is rewritten on refresh. That is not a new interactive grant.
3. Confirm the refresh implementation can use that pair: non-empty refresh token, token endpoint and client id present, and the force-refresh path posts that seed when the access token is expired or the resource returns 401. Reading that function is enough. Do not call the token endpoint.
4. Fetch the same two metadata documents as step 4. Protected-resource scopes that omit `offline_access` while the authorization server lists it do not mean this stored grant is broken. If the token file already has a refresh token, the scope merge is unnecessary for this connector. Say that explicitly so a later reader does not reconnect it "to pick up the fix."
5. Do not POST `grant_type=refresh_token` to prove the path. A successful refresh can rotate the refresh token and invalidate the one the running app still holds.

Answer the coverage question from the code and the stored files, not from "this one server works":

- A stored refresh token plus client info means this connector already refreshes on expiry or 401. The scope-merge change did not save it.
- The scope merge only helps the next interactive login, and only when the authorization server advertises `offline_access` and the protected-resource list omitted it. The previous token file is unchanged until the user Connects with OAuth again on a binary that contains the merge.
- Still uncovered: the authorization server does not list `offline_access` and does not issue a refresh token; the provider requires a non-scope parameter such as `access_type=offline`; the connector is a pasted API token with no OAuth grant; the server revokes the refresh token, rotation fails, or the refresh response omits the old refresh token and the client does not keep it.
- A connector that is connected right now is not evidence the merge covers it.

## Pitfalls

- A future expiry does not mean the bearer is accepted. The resource can 401 before expiry; `ForceRefresh` still errors if `refresh_token` is empty.
- An authorization server that lists `refresh_token` in `grant_types_supported` can still omit `refresh_token` in the token response when the authorize request lacked `offline_access`.
- Do not debug the model-provider refresh path (xAI, Codex, and similar) for an MCP `connector-*` failure. MCP tokens are under `mcp-oauth/`.
- Do not print or commit credential files. A redacted key dump is the artifact.
- Do not change both the catalog repo and the client just because the user asks "both?". Trace whether the catalog field is copied into settings and whether login reads that field. If either hop drops scopes, the catalog edit is a no-op.
- A working scope merge still does not repair an already stored access-only token. The next interactive login is mandatory.
- A live refresh proof is mtime plus a non-empty refresh token, not a token-endpoint call. Rotating a grant the running process still holds is a worse outcome than an unproven path.
- Do not generalize one repaired login into "most MCP connectors now refresh." Static API tokens, servers that never advertise `offline_access`, and grants that fail rotation stay broken.
- Do not treat a fleet-wide `protocol` error as a missing refresh token when a no-auth server failed the same way, or when every token file already has a refresh token. Reconnect once before editing login code.
- Reconnecting a healthy grant does not rotate it. The dangerous call is posting `grant_type=refresh_token` yourself. `reconnect_mcp_server` is the right probe for a shared handshake stall.