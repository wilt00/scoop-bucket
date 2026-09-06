# SourceForge guidance

Use this guidance whenever an application's downloads, project metadata, or source repository are hosted on SourceForge.

## Project and file discovery

- Start with the project REST endpoint, `https://sourceforge.net/rest/p/<project>`. Its `tools` entries identify source-control mounts and anonymous clone URLs without requiring browser-page navigation.
- Inspect the complete files listing at `https://sourceforge.net/projects/<project>/files/` for every release asset, architecture, checksum, signature, source archive, and release date.
- SourceForge pages can be protected by JavaScript or Cloudflare challenges. Prefer the REST endpoint, direct downloads, and local Git operations over trying to scrape protected code-browser pages.
- Use stable download URLs in this form when possible:

  ```text
  https://downloads.sourceforge.net/project/<project>/<path>/<filename>
  ```

  Follow redirects while testing and confirm that the response is the intended file rather than HTML.

## Source repositories and version pins

- Obtain the repository clone URL from the project REST metadata and clone it locally. A common Git URL is `https://git.code.sf.net/p/<project>/<mount-point>`, but do not assume the mount point is `code`.
- When a manifest must stop at the last release with published source, compare the local repository's tags and latest commits with the dates and versions in the SourceForge files listing.
- Inspect commits after the final matching release tag. Documentation-only commits do not establish source availability for a later binary.
- Do not rely on the project's “open source” description as proof that source exists for every binary release.
- For an intentional source-availability pin, omit `checkver` and `autoupdate` unless a deliberately constrained version check still has maintenance value, and explain the pin in `notes`.

## Hashes

- SourceForge's files page commonly embeds per-file SHA-256, SHA-1, and MD5 values in its `net.sf.files` metadata. These values are useful for corroborating a hash computed from the downloaded file.
- Treat hosting-platform metadata hashes as platform-generated metadata, not as independently published upstream checksum artifacts. Do not use them as remote checksum sources in `autoupdate`.
- For a fixed manifest, download through the exact manifest URL, compute SHA-256 locally, and compare it with the SourceForge metadata when available.
- Continue to look for separately uploaded checksum or signature files; those may qualify as upstream-published verification artifacts.

## Licenses

- SourceForge's project-level license categories may combine the application's license with licenses of bundled libraries, or may be stale.
- Inspect the authoritative source tree's license files and the contents of the distributed archive. Use the application's actual license while accounting for materially bundled components rather than copying SourceForge's category list verbatim.

## Validation

- Verify the redirected filename, computed hash, archive layout, and executable architecture.
- Perform a real Scoop install when practical. A valid schema and successful download do not prove that extraction, host-architecture selection, shortcuts, and persistence work.
- After testing, uninstall the app and remove only test-created persistence and cache data. Scoop uninstall does not purge persisted data by default.
