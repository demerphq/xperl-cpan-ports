# XPerl CPAN ports

This repository holds reviewed compatibility patches for original CPAN
releases and migration recipes for recurring XPerl incompatibilities. The
XPerl installer can use a local checkout or a pinned snapshot of this
repository. Ordinary CPAN installation does not require this registry.

Do not add a patch solely because a distribution fails: first identify an
XPerl compatibility issue and verify the proposed change.

## Layout

```text
registry.json
data/<prefix>/<Author>/<Distribution>/index.json
data/<prefix>/<Author>/<Distribution>/status.json
data/<prefix>/<Author>/<Distribution>/patches/<patch>.patch
data/<prefix>/<Author>/<Distribution>/evidence/<record>.json
recipes/<recipe-id>.md
authors/<first>/<first-two>/<Author>.json
upstream-queue/<first>/<first-two>/<Author>/<entry>.json
status/SUMMARY.md
status/UNRESOLVED.md
status/bundled-with-xperl.json
```

Look up a module in the CPAN index first. Then use the resolved author and
distribution to find its registry index. The layout is in
[SHARDING.md](SHARDING.md). The format and matching rules are in
[FORMAT.md](FORMAT.md); submission guidance is in
[CONTRIBUTING.md](CONTRIBUTING.md). The current patch audit and clean-release
retest priorities are in [PATCH_REVIEW.md](PATCH_REVIEW.md).

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

Author consent for upstream XPerl patches and the review queue are described
in [AUTHOR_POLICY.md](AUTHOR_POLICY.md). Author records stay in repository 0
when distribution data is sharded.

Use [PRIORITIZATION.md](PRIORITIZATION.md) and `bin/river-priorities` to rank
candidate ports by their River of CPAN reach alongside local XPerl build
status. This report is optional and separate from installation.
