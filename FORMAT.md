# Patch index format, version 1

Each CPAN author and distribution pair has one `index.json` under the
repository layout described in [SHARDING.md](SHARDING.md). The index content
still uses schema 1. Its `distribution` key is the CPAN distribution name,
not a module name. `releases` contains entries for original CPAN release
archives from that author. An entry's `cpan_path` is relative to the CPAN
authors directory, and `source_sha256` is the digest of the exact downloaded
archive.

This example describes the shape. It is not an installable registry entry:

```json
{
  "schema": 1,
  "distribution": "Example-XS",
  "releases": [
    {
      "version": "4.40",
      "cpan_path": "E/EX/EXAMPLE/Example-XS-4.40.tar.gz",
      "source_sha256": "<64 lowercase hexadecimal digits>",
      "patch_sets": [
        {
          "id": "hash-api-v1",
          "xperl": {
            "min_inclusive": "v5.45.0",
            "max_exclusive": "v5.47.0"
          },
          "patches": [
            {
              "path": "patches/hash-api-v1.patch",
              "sha256": "<64 lowercase hexadecimal digits>"
            }
          ],
          "recipes": ["hash-storage-v1"]
        }
      ]
    }
  ]
}
```

## Matching

1. Resolve the requested module through the CPAN index to a CPAN author,
   distribution, and release. Explicit author selection is a future installer
   capability.
2. Require an exact match for author, distribution name, release version, CPAN archive
   path, and source SHA-256 digest. Never infer compatibility from a similar
   filename or version alone.
3. Select a patch set whose XPerl version interval contains the running
   interpreter's version. `min_inclusive` and `max_exclusive` are both
   required. Compare them as Perl versions, not as strings.
4. Require exactly one matching patch set. An empty `patch_sets` array means
   that the release has no registered patch. Overlapping intervals for the
   same release are invalid until a future format defines explicit selectors.
5. Verify each patch digest and apply patches in array order to a fresh
   working copy. A failed patch stops the install before any build step.

Distribution names, patch-set IDs, recipe IDs, and relative paths must be
validated before use. Reject absolute paths, `..` components, symlinks that
escape the registry, unknown schema versions, duplicate release identities,
and duplicate patch-set IDs. A configured registry that cannot be read or
validated should report an error. Users can explicitly disable it and use
the ordinary CPAN path.

The exact format of optional platform or build selectors will be defined when
a verified patch requires one. Do not add ad hoc keys to individual records.

## Evidence

Test evidence belongs in `evidence/`, separate from the selection index. A
record should identify the source digest, patch-set ID, patch digests, XPerl
version and configuration, platform, build and test commands, results, and
date. Evidence says what was tested; the version interval says where a patch
may apply. The two are deliberately distinct.

Recipes are Markdown files under `recipes/`, named by the IDs in patch sets.
They explain the symptom, affected XPerl change, preferred port, compatibility
constraints, and validation. An installer may pass relevant recipes to an
external agent, but a recipe is not an automatically applied patch.
