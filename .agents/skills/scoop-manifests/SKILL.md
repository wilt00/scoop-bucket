---
name: scoop-manifests
description: Create, update, and review Scoop manifests in this repository. Use whenever working on JSON files under bucket/ or archive/, especially architecture, checkver, and autoupdate fields.
---

# Scoop manifests

Follow `app-name.template.json` and existing manifests in `bucket/`, while keeping each manifest as simple as the upstream release layout permits.

## Scoop documentation

The `wiki/` directory is a local checkout of Scoop's wiki and contains the authoritative documentation, manifest reference, autoupdate guidance, and best practices. Consult the relevant pages there when creating or reviewing manifests, especially:

- `wiki/App-Manifests.md`
- `wiki/App-Manifest-Autoupdate.md`
- `wiki/Creating-an-app-manifest.md`
- `wiki/Pre-Post-(un)install-scripts.md`
- `wiki/Persistent-data.md`

Prefer this repository-local documentation over assumptions about Scoop behavior.

## Property placement

- Put properties at the highest shared level that is valid.
- Keep `architecture` entries limited to values that genuinely differ by architecture, typically `url` and `hash`.
- In particular, keep `extract_dir`, `extract_to`, `bin`, `shortcuts`, and similar properties at the top level when their values are identical for every architecture.
- Move a property into an architecture entry only when its value actually differs between architectures.

## Version checks

Prefer Scoop's standard GitHub checkver whenever the repository uses conventional release tags:

```json
"checkver": {
    "github": "https://github.com/owner/repo"
}
```

Only use a custom `url` and `regex` when standard GitHub checkver cannot identify the intended releases, such as repositories with multiple products in one release feed or nonstandard product-prefixed tags. Before adding a custom regex, verify why the standard form is insufficient.

Keep custom regexes narrowly scoped to the intended asset or tag, and test that they extract the current version.

## Running checkver

Run Scoop's `checkver.ps1` from the repository root to verify version detection and update a manifest:

```powershell
$app = "manifest-name"
& "$env:USERPROFILE\scoop\apps\scoop\current\bin\checkver.ps1" -App $app -Dir .\bucket\ -Update -Force
```

Set `$app` to the manifest name without the `.json` extension. `-Update` rewrites the manifest with the detected version, URL, and hash; review the resulting diff. Omit `-Update` when only testing version detection. Use `-Force` to check even when the current version appears up to date.

## Workflow

1. Inspect `app-name.template.json` and a few comparable manifests.
2. Inspect the latest upstream release, asset names, archive layout, and license.
3. Use the standard GitHub checkver unless upstream naming makes it unsuitable.
4. Minimize architecture-specific properties.
5. Validate JSON, the downloaded asset hash, archive paths, and checkver extraction.
6. Run the repository test suite from the repository root after making changes:

   ```powershell
   .\bin\test.ps1
   ```

   Investigate and report any failures. Do not suppress or fix unrelated failures without the user's approval.
7. Run `git diff --check`.
8. Do not modify unrelated uncommitted files.
