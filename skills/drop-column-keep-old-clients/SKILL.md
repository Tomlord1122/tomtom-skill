---
name: drop-column-keep-old-clients
description: >-
  Drop a database column that still appears in API requests and responses while old clients stay deployed. Use when removing a flag, filter, or field from schema, sqlc or generated queries, and frontend types, and the old app must not 400 or lose rows. Do not use for renaming a field in place, OpenAPI generated-client drift, or a column nothing still reads.
metadata:
  cometline:
    origin: self-improvement
tags:
  - api
  - database
  - migration
---

# Drop a column without breaking old clients

A column can leave the database before every client leaves the field. Accept the old request field and ignore it. Keep emitting the old response field with a constant that matches the rows you already verified. Drop the column only after queries no longer mention it, and only after a linked read shows no rows would change meaning.

## Steps

1. Grep every name the field has, not just the column. Search snake_case, PascalCase, the query param, and cache-key helpers in SQL, generated query code, handlers, request structs, and frontend types. `SELECT *` and `b.*` still return a column you removed from the explicit column list.
2. Before writing a drop migration, query the linked database. Do not push. Count rows that would change visibility or meaning if the filter disappeared, for example unpublished versus published. If any such rows exist, stop. Deleting the column would publish or hide them.
3. If local and remote migration histories disagree, still do not push. A read-only linked query is enough to decide whether the drop is safe. Leave the history mismatch for a separate repair.
4. Edit the query source, not the generated client. Remove the column from `INSERT`, `UPDATE`, `RETURNING`, and `WHERE`. Delete list queries that existed only to apply the old filter, and point every caller at the remaining unfiltered query. Then regenerate (`sqlc generate` or the repo's equivalent). Hand-editing generated query code leaves the next generate putting the column back.
5. Keep the JSON field on request structs with no `binding:"required"`. Decode it and do not pass it into the write. A missing field and an old client that still sends it must both succeed. Do not answer 400 for an unknown or unused field the old client always sent.
6. Keep the JSON field on response structs and set it to the constant you verified in step 2 (here, every live row was already true, so responses send `true`). Old decoders that require the field keep working. New clients stop reading it.
7. Ignore the old query param instead of rejecting it. Document that in the handler. Remove it from the cache key so `?published=true` and `?published=false` do not split one list into two entries.
8. Remove the field from the frontend types and from every create, update, and page payload in the same change. A type that no longer has the field will fail check if any call site still sends it.
9. Build the service and typecheck the client. The first failure is often a leftover struct field (`PublishedOnly`, generated `IsPublished`) that grep on the source queries missed. Fix that, then rebuild. Do not deploy or push the migration until the user asks.
10. When the user does ask to deploy, split additive schema from the drop. New queries that no longer select the column are safe on the old database. The old binary is not safe after the column is gone: its `SELECT *` and `INSERT` that still name the column 500. Push additive migrations, deploy the new binary, wait until old machines are stopped, confirm reads and writes, then push the drop alone.
11. Do not use `supabase db push` while a later drop file sits in `supabase/migrations/` and you only want the earlier file. This CLI has no include-one flag. Move the drop file out of the migrations directory, `db push --dry-run --yes`, confirm the dry run lists only the additive file, push for real, then move the drop file back before any commit. A failed `mv` at the start of a chained command must not be followed by a push.
12. Repair history before that push if `supabase migration list` shows a remote-only version. Read the remote column list first. If that version is the same change as a later local file (the column already exists), mark the local version applied and the remote-only version reverted:

```bash
supabase migration repair --status applied <local-version>
supabase migration repair --status reverted <remote-only-version>
supabase migration list
```

`repair --status reverted` only deletes the history row. It does not run SQL. Do not revert a version whose SQL is not already represented by a local applied migration. Push still refuses while any remote version has no local file.

13. If the additive migration creates a table with `uuid_generate_v4()` and the remote push fails with `function uuid_generate_v4() does not exist`, do not assume the extension is missing. Other tables can still show that default. Query `pg_proc` joined to `pg_namespace`. If the function is `extensions.uuid_generate_v4`, write that qualified name in the same migration file and push again. A failed push does not record the version. Use `gen_random_uuid()` only when `uuid-ossp` is absent.

## Pitfalls

- Do not drop the column first and clean the code after. Queries that still select or filter it fail as soon as the migration runs, including against a local database reset from the new migration chain.
- Do not remove the response field in the same change as the column. Old frontends that require it fail decode even when the new frontend typechecks.
- Do not treat "the handler defaults the filter to true" as proof there are no hidden rows. Only a count on the linked database shows that. If the count is not zero, the drop changes who can see those rows.
- Do not push a new migration while `supabase migration list` shows versions present only on one side. The drop is a new file. Repairing history is a different change.
- Do not leave the old flag in the list cache key after the handler ignores it. Two URLs would cache the same rows under different keys.
- A remote-only version that is the same SQL under an older timestamp is repaired by marking the local version applied and the remote-only version reverted. Confirm the column exists with a linked read first. Reverting a version that is not duplicated locally deletes history for SQL you can no longer replay.
- `supabase db push` refuses while any remote version has no local file, even after other versions were repaired. List again after repair. The pending pair should be the additive migration and the drop, nothing remote-only.
- Do not leave the drop file in the migrations directory for a "push only the table" deploy. The CLI applies every pending local file. Moving it aside is the include filter this CLI does not have. Put it back before committing so the drop is not lost from the repo.
- Creating a table with an unqualified `uuid_generate_v4()` fails on a remote whose function lives in `extensions` and whose migration search path does not include it. Qualify it. Do not create a new migration version for a push that never recorded the old version.