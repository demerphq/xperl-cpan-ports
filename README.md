# XPerl CPAN ports

This repository holds reviewed compatibility patches for original CPAN
releases and migration recipes for recurring XPerl incompatibilities. The
XPerl installer can use a local checkout or a pinned snapshot of this
repository. Ordinary CPAN installation does not require this registry.

The registry is intentionally empty until a port has been built and tested.
Do not add a patch solely because a distribution fails: first identify an
XPerl compatibility issue and verify the proposed change.

## Layout

```text
distributions/<Distribution>/index.json
distributions/<Distribution>/patches/<patch>.patch
distributions/<Distribution>/evidence/<record>.json
recipes/<recipe-id>.md
```

Look up a module in CPAN metadata first. Then use the resolved distribution
name to find its registry index. The format and matching rules are in
[FORMAT.md](FORMAT.md); submission guidance is in
[CONTRIBUTING.md](CONTRIBUTING.md).

Patch files modify a working copy of the upstream release. They must never
replace the original archive in the installer's cache. The installer records
the source archive digest, registry revision, selected patch set, patch
digests, XPerl version, and test result in its installation receipt.
