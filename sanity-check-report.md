# Sanity Check Report

- Repository: simatic-ax/automationbase (`d:\AX\GitHubCommunity\Conveyor_workspace\automationbase`)
- Date: 2026-09-10
- Summary: 25 PASS, 1 FAIL, 4 TODO

## README.md Validation

- PASS: `README.md` exists at repository root.
- PASS: `## Description` section exists with meaningful, non-placeholder content explaining the library's purpose.
- PASS: `## Getting Started` → `### Installation` section provides install instructions via `apax add @simatic-ax/automationbase`.
- PASS: `## Contribution` section exists with clear contributor guidance (matches accepted "Contributing" variant).
- PASS: `## License and Legal Information` section exists and links to `LICENSE.md`.
- PASS: Fenced code blocks are balanced — 10 opening/closing ``` pairs in `README.md` (lines 27-239), all correctly paired, including indented fences inside the "Best Practices" numbered list.
- PASS: No obvious typos found in headings or prose.

## apax.yml Validation

- PASS: `apax.yml` exists at repository root.
- PASS: `description` is present and non-empty ("Foundation library for SIMATIC AX automation applications...").
- PASS: `author` is present ("Siemens AG").
- PASS: `name` uses the `@simatic-ax/` scope (`@simatic-ax/automationbase`).
- PASS: `version` is exactly `0.0.0-placeholder`.
- PASS: `targets` contains both `s7` and `llvm`.
- PASS: `catalogs` contains `"@ax/simatic-ax": ^2510.18.1` (matches `^2510.x.y`).
- PASS: `registries` section exists (`@simatic-ax` → GitHub npm registry).
- PASS (fixed since last run): `files` now includes `bin\s7` and `bin\llvm`, resolving the previously reported missing target entries.
- PASS: All `files` entries (`README.md`, `LICENSE.md`, `docs`, `bin\s7`, `bin\llvm`, `src`, `snippets`) resolve to existing paths in the repository.
- PASS (fixed since last run): `devDependencies` now consistently use range versions — `@simatic-ax/mocks` changed from pinned `4.3.3` to `^4.3.3`.
- TODO: `files` entries for the bin targets use backslashes (`bin\s7`, `bin\llvm`) rather than forward slashes. This resolves on Windows, but forward slashes (`bin/s7`, `bin/llvm`) are recommended for portability with Linux-based CI/apax tooling.
- FAIL (new): `dependencies` now contains a local file-path dependency that must not ship in a public repository:
  ```yaml
  "@simatic-ax-internal/contributors-kit": file:../../../Fokuswoche_2607_2/contributors-kit/simatic-ax-internal-contributors-kit-0.0.0-replace-in-pipeline.apax.tgz
  ```
  - It references a path outside the repository (`../../../Fokuswoche_2607_2/...`), which will not resolve for any other contributor, CI runner, or after migration to public GitHub.
  - The package scope `@simatic-ax-internal` indicates an internal-only package, inappropriate as a dependency of a public library.
  - The filename contains the placeholder marker `-replace-in-pipeline`, indicating it is meant to be substituted by a build pipeline and should not be committed as-is.
  - It also leaks a local/internal folder name (`Fokuswoche_2607_2`) into the committed repository history.
  - Remediation: remove this dependency before migration, or replace it with a proper versioned, publicly resolvable registry reference.

## Markdown Link Validation

- PASS: Internal links from `README.md` to `docs/EquipmentBase.md`, `docs/OperatingModes.md`, `docs/StartupWarning.md`, `docs/Release.md`, `docs/Supervision.md`, and `LICENSE.md` all resolve to existing files.
- PASS: Anchor link `docs/EquipmentBase.md#error-handling` — target file exists (anchor content not deep-validated).
- TODO: External links (`https://github.com/simatic-ax/.github/blob/main/docs/personalaccesstoken.md`) are syntactically valid; remote reachability was not verified in this environment.

## .gitattributes Validation

- PASS: `.gitattributes` exists at repository root and contains `*.st linguist-detectable=false`, which is functionally equivalent to the reference rule — it prevents GitHub linguist from misclassifying `.st` files as Smalltalk.

## LICENSE Validation

- PASS: `LICENSE.md` exists at repository root (Siemens Royalty-free Licensed Material terms, v1.4).
- PASS: `README.md` license section links correctly to `./LICENSE.md` (not a bare `LICENSE`).
- TODO: Byte-for-byte comparison against the approved reference license at `https://github.com/simatic-ax/.github/blob/main/LICENSE.md` was not performed — no network fetch capability available in this session. Recommend a manual diff before migration.

## Disclaimer Validation

- PASS (fixed since last run): `.github/Disclaimer.md` now exists, is non-empty, and contains plausible standard Siemens disclaimer content.
- TODO: Byte-for-byte comparison against the approved source `.github/skills/sanity-check/Disclaimer.md` was not performed — that reference file is not present in this repository/environment. Recommend a manual diff against the official template before migration.

## CODEOWNERS Validation

- PASS: `CODEOWNERS` exists at repository root, is non-empty, and contains a plausible owner entry (`* @simatic-ax/toa-teamofaxion`).

## Applied Fixes

- None applied by the agent. The following were fixed by the user between runs:
  - Added `.github/Disclaimer.md`.
  - Added `bin\s7` and `bin\llvm` to `apax.yml` `files`.
  - Changed `@simatic-ax/mocks` in `devDependencies` from a pinned version to a range version (`^4.3.3`).
- A new blocking issue was introduced in this same edit: a local `file:` path dependency in `apax.yml` (`@simatic-ax-internal/contributors-kit`) — see apax.yml Validation above. This must be resolved before migration.
