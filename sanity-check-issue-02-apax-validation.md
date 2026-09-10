# [Sanity Check] apax.yml Validation

## Summary

The previously reported `files`/`bin/<target>` issue has been fixed. However, a new blocking issue was introduced: `dependencies` now contains a local `file:` path dependency that must not ship in a public repository.

## Affected Files

- `apax.yml`

## Findings

- FIXED: `files` now includes `bin\s7` and `bin\llvm`, matching the declared `targets`.
- TODO: `bin\s7` / `bin\llvm` use backslashes; forward slashes (`bin/s7`, `bin/llvm`) are recommended for cross-platform consistency.
- FIXED: `devDependencies` now consistently use range versions (`@simatic-ax/mocks` is now `^4.3.3`).
- FAIL (new): `dependencies` contains:
  ```yaml
  "@simatic-ax-internal/contributors-kit": file:../../../Fokuswoche_2607_2/contributors-kit/simatic-ax-internal-contributors-kit-0.0.0-replace-in-pipeline.apax.tgz
  ```
  - Points to a path outside the repository — will not resolve for other contributors, CI, or after public migration.
  - `@simatic-ax-internal` scope indicates an internal-only package, not appropriate for a public dependency tree.
  - Filename contains the placeholder marker `-replace-in-pipeline`, indicating it should be substituted by a pipeline and not committed as-is.
  - Leaks a local/internal folder name (`Fokuswoche_2607_2`) into repository history.

## Acceptance Criteria

- Remove the `file:` dependency on `@simatic-ax-internal/contributors-kit`, or replace it with a proper versioned, publicly resolvable registry reference.
- Use forward slashes for `bin/s7` and `bin/llvm` in `files`.
- Re-run `apax install` after modifying `apax.yml` and confirm it completes without errors.

## Note

This file is a draft issue template for later GitHub issue creation via MCP.
