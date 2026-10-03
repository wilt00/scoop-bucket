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

- Scoop's `architecture` blocks select instructions according to the host architecture; they do not merely document a binary's PE machine type.
- **Check host-architecture selection for every manifest, even when there is only one asset.** A top-level `url`/`hash` is not an x64 declaration: Scoop may select it on 32-bit and ARM64 hosts too. Put a Windows x64-only asset under `architecture.64bit` (`url` and `hash`), and put its update URL under `autoupdate.architecture.64bit`. Do this even if the manifest has no other architecture blocks. An x64 filename or PE machine type is a reason to investigate compatibility, not proof that Scoop will reject unsupported hosts automatically.
- Put properties at the highest shared level that is valid. Keep a URL and hash at the top level **only when that same asset actually works on every host architecture Scoop would select it for**. For example, an x86 application that runs on both 32-bit and 64-bit Windows through WOW64 can use a top-level URL; do not restrict it to `architecture.32bit` based on PE type alone. Use architecture blocks to prevent unsupported hosts from receiving an asset.
- Keep `architecture` entries limited to values that genuinely differ by architecture, typically `url` and `hash`.
- Keep `extract_dir`, `extract_to`, `bin`, `shortcuts`, and similar properties at the top level when their values are identical for every architecture; move them into architecture only when paths or layouts differ.
- Support every Windows architecture for which upstream publishes or explicitly supports a working asset, including ARM64 and 32-bit.
- Verify each distributed binary's architecture directly rather than inferring it from the asset name or release text. For Windows executables, inspect the PE machine type with a suitable tool such as `dumpbin /headers` or by reading the PE header; inspect executables inside archives as needed. Treat this as separate from deciding which host architectures can run the program.
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

When creating a manifest with `checkver` and `autoupdate`, or changing its `version`, `url`, `hash`, `checkver`, `autoupdate`, or URL/hash architecture mapping, **always run `checkver.ps1 -Update -Force`**; a version-only check or schema validation is not a substitute. Do not rerun checkver for changes limited to unrelated fields such as `persist`, `notes`, `bin`, or `description`; test those changes directly instead. Before a required checkver run, ensure each URL has a corresponding nonempty `hash` entry. If the hash is not yet known, use a temporary 64-character zero placeholder (`"hash": "0000000000000000000000000000000000000000000000000000000000000000"`), one per URL for URL arrays or one in each architecture block with a URL. An empty string (`"hash": ""`) does not work: Scoop treats it as missing and may try to update a nonexistent `architecture` block. Confirm that checkver replaces every placeholder; review the resulting version, URL, hash, and diff. Never leave placeholder hashes in a finished manifest.

For manifests intentionally pinned to a particular version, omit both `checkver` and `autoupdate`. Add concise `notes` explaining a non-obvious pin. Sometimes this is because the upstream release is old and we no longer expect it to be updated; sometimes it is because we intentionally want to avoid newer releases. In this latter case, include the version number in the manifest name following the Scoop Versions bucket convention: `<manifest-name><major>` with no separator, e.g. `appname2` for a manifest pinned to version 2.x.

## Autoupdate hashes

Before drafting or changing a manifest, inspect all release assets for upstream-published checksum or signature files. Match each checksum to its exact asset and architecture.

Do not extract autogenerated hashes from a GitHub Releases page. Only use a GitHub-hosted checksum when the package author has explicitly published it as an independent release artifact or included it in the PR description. GitHub API-generated asset `digest` values and hashes merely displayed by GitHub are not upstream-published checksums.

Use qualifying published checksums whenever available. Put shared hash configuration at the top of `autoupdate` when it applies to every configured architecture:

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

Otherwise, put `hash` in the matching architecture block, including for single-architecture manifests. Do not duplicate identical configuration across architectures. If upstream publishes no qualifying checksum, let Scoop download and hash the asset. Always inspect the checksum file, verify it against the download, and test autoupdate.

## Runtime dependencies

Do not rely only on running the executable to detect Microsoft Visual C++ runtime dependencies: an already-installed redistributable masks the requirement. Inspect the executable's dynamically linked libraries from a Git Bash/MSYS shell instead:

```shell
ldd ./program.exe | grep VCRUNTIME
```

Do not assume empty or obviously incomplete `ldd` output proves that no runtime is needed. Older Windows GUI executables may show only the WOW64 loader chain. In that case inspect the PE import table with another available tool, such as `dumpbin /dependents`, and look for `VCRUNTIME`, `MSVCP`, `MSVCR`, or UCRT imports.

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

- Always prefer an upstream standalone binary or portable archive over an installer. If a new package is available only through executable installers, stop and ask the user for confirmation before continuing to create the manifest.
- Prefer Scoop's native `extract_dir`, `extract_to`, and MSI extraction behavior over custom extraction scripts.
- Use `extract_to` when an archive contains files such as `manifest.json` that would collide with Scoop's own metadata.
- For archives served through a query-string URL such as `https://example.org/download/?f=app-1.0.zip`, Scoop derives the local filename from the URL path (`download`), not the `f` parameter. Without a `.zip` filename, it may download and verify the archive but skip extraction, leaving the installation incomplete. Append a filename fragment (`#/app-1.0.zip`) to both the manifest URL and its autoupdate URL template; verify with a real install, not just a successful hash check or `checkver` run.
- Rename a downloaded executable with a URL fragment such as `#/program.exe` instead of adding a rename script or an unnecessarily complex aliased `bin` entry. Do not add a URL fragment when the upstream URL already downloads the file under the desired name.
- Put an architecture-dependent `extract_dir` in each architecture entry, but do not duplicate an invariant `extract_dir` in `autoupdate`.

## Scripts and persistence

- Use the simplest suitable script property. Prefer a concise `pre_install` command over an `installer.script` wrapper for one-step preparation.
- Write idiomatic PowerShell: pipeline objects, use `-ErrorAction Ignore` for expected missing paths, and use `-Force` where replacement is intended. Avoid redundant existence checks and loops.
- Account for global installs when scripts use registry hives or user-specific paths; select HKLM instead of HKCU where appropriate.
- This repository intentionally differs from upstream Scoop guidance for data naturally written outside the install directory, such as under `%LOCALAPPDATA%`, `%APPDATA%`, or the user profile. Prefer the simplest mechanism that preserves data: leave such files where the program naturally creates them, and do not relocate or junction them into Scoop-managed persistence directories.
- When a program naturally creates persistent files outside the install directory, document the paths and behavior in the final report or PR notes so they are known if the manifest is later contributed upstream.
- Test persistence inside the install directory against the application's actual write behavior. Distinguish replacing a file, such as writing a temporary file and renaming it over the original, from opening the same file with truncation and rewriting it. A hardlink survives an in-place truncate/rewrite such as `fopen(..., "wb")`, but it does not preserve a file that the application replaces with a new filesystem entry. Copy replacement-written files during install/uninstall and overwrite deliberately.
- Keep JSON script structure valid: `installer`, `uninstaller`, and hook properties must have the exact scalar/array/object shape Scoop expects.

## Metadata and user experience

- Write concise, neutral descriptions rather than marketing copy or exhaustive feature lists, and end them with a period.
- When compatible with the above, prefer the app's own description of itself over a third-party summary. Avoid repeating the app name in the description.
- Treat catalog- or hosting-level license metadata as a lead rather than definitive evidence. It may aggregate licenses from bundled libraries or be stale. Inspect the application's primary license file and account for materially bundled components before selecting the manifest license.
- For GitHub-hosted packages, prefer a non-GitHub product homepage whenever one exists and is authoritative. Otherwise use the source repository. Avoid unnecessary trailing slashes.
- Add `notes` when packaging one of several non-obvious upstream variants or when users need essential post-install context.

## Source availability

- Clone the authoritative source repository locally; do not explore a Git repository through web pages or raw-file HTTP requests.

## Running checkver

Run Scoop's `checkver.ps1` from the repository root to verify version detection and update a manifest:

```powershell
$app = "manifest-name"
& "$env:USERPROFILE\scoop\apps\scoop\current\bin\checkver.ps1" -App $app -Dir .\bucket\ -Update -Force
```

Set `$app` to the manifest name without the `.json` extension. Run this command for new manifests and release/update-field changes listed above, even when the recorded version is current; skip it for unrelated changes such as persistence alone. Before running, make sure each URL has a corresponding nonempty `hash` entry (use the temporary zero placeholder above if necessary). Confirm that every placeholder was replaced, review the resulting diff, and verify each hash is for the exact release asset. A separate version-only check may supplement, but never replace, a required update run.

## Workflow

1. Inspect `app-name.template.json` and a few comparable manifests.
2. Inspect the latest upstream release, all asset names (including checksum/signature files), archive layout, and license.
3. Use the standard GitHub checkver unless upstream naming makes it unsuitable.
4. Determine which Windows host architectures can run each asset, then verify that Scoop's top-level versus `architecture` URL selection matches that support. For x64-only assets, require `architecture.64bit` and matching `autoupdate.architecture.64bit`, even in single-architecture manifests; keep invariant properties at the top level.
5. Validate JSON, the downloaded asset hash, archive paths, and checkver extraction. Schema validation alone does not detect an x64-only URL accidentally exposed at the top level.
6. Preserve repository-required file formatting, including CRLF line endings in this repository.
7. Run the repository test suite from the repository root after making changes:

   ```powershell
   .\bin\test.ps1
   ```

   Investigate and report any failures. Do not suppress or fix unrelated failures without the user's approval.
8. Do not modify unrelated uncommitted files.
9. As the last step in verification, when practical, perform a real local Scoop install and uninstall. Confirm with the user before proceeding to this step. Schema validation does not detect host-architecture selection errors, extraction mistakes, broken shortcuts, or persistence setup failures. Check whether the app was already installed before testing and never uninstall or overwrite a pre-existing user installation.
10. Clean only artifacts created by the test. A normal uninstall retains persisted data and download cache entries, so remove those test-created items as well as confirming that the app directory and shortcut are gone.

## Hosting-specific guidance

When upstream uses SourceForge, read [sourceforge.md](sourceforge.md) in full before researching or drafting the manifest.
