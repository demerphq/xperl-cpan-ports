# XPerl CPAN ports

This repository holds reviewed compatibility patches for original CPAN
releases and migration recipes for recurring XPerl incompatibilities. The
XPerl installer can use a local checkout or a pinned snapshot of this
repository. Ordinary CPAN installation does not require this registry.

Do not add a patch solely because a distribution fails: first identify an
XPerl compatibility issue and verify the proposed change.

## Layout

```text
distributions/<Distribution>/index.json
distributions/<Distribution>/patches/<patch>.patch
distributions/<Distribution>/evidence/<record>.json
recipes/<recipe-id>.md
status/distributions/<Distribution>.json
status/SUMMARY.md
status/UNRESOLVED.md
```

Look up a module in CPAN metadata first. Then use the resolved distribution
name to find its registry index. The format and matching rules are in
[FORMAT.md](FORMAT.md); submission guidance is in
[CONTRIBUTING.md](CONTRIBUTING.md).

Patch files modify a working copy of the upstream release. They must never
replace the original archive in the installer's cache. The installer records
the source archive digest, registry revision, selected patch set, patch
digests, XPerl version, and test result in its installation receipt.

The status records include both unpatched and patched builds, and retain
earlier failures after a later success. Import local installer receipts with
the XPerl interpreter:

    /path/to/xperl/bin/perl bin/import-receipts --cache /path/to/installer-cache

The importer writes compact records without machine-specific installation
paths or full build logs. See [status/README.md](status/README.md).

The planned repository and directory layout is described in
[SHARDING.md](SHARDING.md). The current paths above remain the version 1
layout until the installer supports the new lookup scheme.

Use [PRIORITIZATION.md](PRIORITIZATION.md) and `bin/river-priorities` to rank
candidate ports by their River of CPAN reach alongside local XPerl build
status. This report is optional and separate from installation.
