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

## Property placement and architecture

- Put properties at the highest shared level that is valid.
- Keep `architecture` entries limited to values that genuinely differ by architecture, typically `url` and `hash`.
- Keep `extract_dir`, `extract_to`, `bin`, `shortcuts`, and similar properties at the top level when their values are identical for every architecture; move them into architecture only when paths or layouts differ.
- Support every Windows architecture for which upstream publishes a working asset, including ARM64 and 32-bit. Conversely, use `architecture` to restrict a package when upstream only supports one architecture.
- Do not expose GUI-only applications through `bin`. For CLI-first applications, do not add a redundant Start Menu shortcut unless it has real value.

## Version checks

Always use Scoop's standard GitHub checkver when the app is hosted on Github, as this allows Scoop to manage required API authentication and rate limiting.

```json
"checkver": {
    "github": "https://github.com/owner/repo"
}
```

When the standard GitHub checkver regex is insufficient to extract a version, for example because multiple apps are released in the same repository, use a custom `jsonpath` and `regex` to extract the version from the upstream release feed or release page HTML. For example:

```json
"checkver": {
    "github": "https://api.github.com/repos/owner/repo/releases",
    "jsonpath": "$[*].tag_name",
    "regex": "\"product-v([\\d.]+)\""
}
```

When release order is not reliable or version selection requires semantic comparison, use a short `checkver.script` to filter, cast versions to `[version]`, sort, and return the result rather than trusting feed order.

Keep regexes constrained to the intended tags or assets, escape literal filename dots such as `\.zip`, and use named captures when an asset variant must be carried into autoupdate as `$matchName`.

As always, verify with `checkver.ps1`.

## Autoupdate hashes

Before drafting or changing a manifest, inspect all release assets for upstream-published checksum or signature files. Match each checksum to its exact asset and architecture.

Use published checksums whenever available. Put shared hash configuration at the top of `autoupdate` when it applies to every configured architecture:

```json
"hash": {
    "url": "$url.sha256"
}
```

or:

```json
"hash": {
    "url": "$baseurl/SHA256SUMS"
}
```

Otherwise, put `hash` in the matching architecture block, including for single-architecture manifests. Do not duplicate identical configuration across architectures. Do not use GitHub API-generated asset `digest` values; if upstream publishes no checksum, let Scoop download and hash the asset. Always inspect the checksum file, verify it against the download, and test autoupdate.

## Runtime dependencies

Do not rely only on running the executable to detect Microsoft Visual C++ runtime dependencies: an already-installed redistributable masks the requirement. Inspect the executable's dynamically linked libraries from a Git Bash/MSYS shell instead:

```shell
ldd ./program.exe | grep VCRUNTIME
```

For example, output such as the following confirms a dependency on the Visual C++ runtime:

```text
VCRUNTIME140.dll => /c/WINDOWS/SYSTEM32/VCRUNTIME140.dll (0x7ffd28800000)
```

When a `VCRUNTIME` dependency resolves from Windows/System32, recommend the current runtime through `suggest` rather than scripting its installation:

```json
"suggest": {
    "vcredist": "extras/vcredist2022"
}
```

Do not add the suggestion when the package ships and resolves its own runtime DLLs. Only add suggestions for dependencies that are actually required or materially useful. Check for other material runtime requirements too, such as WebView2, Java, or an Android SDK, and use the appropriate bucket manifest.

## Extraction and filenames

- Prefer Scoop's native `extract_dir`, `extract_to`, and MSI extraction behavior over custom extraction scripts.
- Use `extract_to` when an archive contains files such as `manifest.json` that would collide with Scoop's own metadata.
- Rename a downloaded executable with a URL fragment such as `#/program.exe` instead of adding a rename script or an unnecessarily complex aliased `bin` entry.
- Put an architecture-dependent `extract_dir` in each architecture entry, but do not duplicate an invariant `extract_dir` in `autoupdate`.

## Scripts and persistence

- Use the simplest suitable script property. Prefer a concise `pre_install` command over an `installer.script` wrapper for one-step preparation.
- Write idiomatic PowerShell: pipeline objects, use `-ErrorAction Ignore` for expected missing paths, and use `-Force` where replacement is intended. Avoid redundant existence checks and loops.
- Account for global installs when scripts use registry hives or user-specific paths; select HKLM instead of HKCU where appropriate.
- Test persistence against the application's actual write behavior. Hardlinks do not preserve files that the application replaces rather than modifies in place; copy such files during install/uninstall and overwrite deliberately.
- Keep JSON script structure valid: `installer`, `uninstaller`, and hook properties must have the exact scalar/array/object shape Scoop expects.

## Metadata and user experience

- Write concise, neutral descriptions rather than marketing copy or exhaustive feature lists, and end them with a period.
- When compatible with the above, prefer the app's own description of itself over a third-party summary. Avoid repeating the app name in the description.
- Prefer the authoritative product website over its source repository when one exists, and avoid unnecessary trailing slashes.
- Add `notes` when packaging one of several non-obvious upstream variants or when users need essential post-install context.

## Running checkver

Run Scoop's `checkver.ps1` from the repository root to verify version detection and update a manifest:

```powershell
$app = "manifest-name"
& "$env:USERPROFILE\scoop\apps\scoop\current\bin\checkver.ps1" -App $app -Dir .\bucket\ -Update -Force
```

Set `$app` to the manifest name without the `.json` extension. `-Update` rewrites the manifest with the detected version, URL, and hash; review the resulting diff. Omit `-Update` when only testing version detection. Use `-Force` to check even when the current version appears up to date.

## Workflow

1. Inspect `app-name.template.json` and a few comparable manifests.
2. Inspect the latest upstream release, all asset names (including checksum/signature files), archive layout, and license.
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
