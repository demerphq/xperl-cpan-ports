# XPerl CPAN ports

This repository holds compatibility patches for original CPAN
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
queues/<investigation>.txt
authors/<first>/<first-two>/<Author>.json
upstream-queue/<first>/<first-two>/<Author>/<entry>.json
status/SUMMARY.md
status/UNRESOLVED.md
status/XS-PATCHES.md
status/XS-PATCHES.json
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

Successful AI repairs enter a configured writable registry automatically.
The installer writes the patch, exact release selector, and portable test
evidence. Review these files and run a clean registry-only install before
committing and publishing them. New recipes are added when a repair exposes
guidance that applies to other distributions.

The status records include both unpatched and patched builds, and retain
earlier failures after a later success. Import local installer receipts with
the XPerl interpreter:

    /path/to/xperl/bin/perl bin/import-receipts --cache /path/to/installer-cache

The importer writes compact records without machine-specific installation
paths or full build logs. See [status/README.md](status/README.md).

`--receipt FILE` imports a named receipt and may be repeated, alone or
alongside `--cache`. A publisher that records one completed distribution at a
time can add `--record-only`:

    /path/to/xperl/bin/perl bin/import-receipts --record-only \
        --receipt /path/to/work/release-XXXX/receipt.json

Record-only mode reads and updates only the named receipts' distribution
records. It applies the same normalization and duplicate removal as a full
import. It leaves `status/SUMMARY.md` and `status/UNRESOLVED.md` unchanged;
refresh them separately with `--rebuild`. Importing an identical receipt, or
another receipt with the same build facts, leaves the record byte-identical.

## Browse build results

Open [status/SUMMARY.md](status/SUMMARY.md) and search for the distribution
name. Each row gives its CPAN author, release version, XPerl version,
platform, latest status, and patch set. Click the distribution name to read
its `status.json`, which retains earlier observations as well as the latest
one. [status/UNRESOLVED.md](status/UNRESOLVED.md) lists recorded failures
whose latest observation has not succeeded.

The linked distribution directory may also contain `index.json` for patch
selection, `patches/` for the actual diffs, and `evidence/` for validation.
The same distribution name can occur under different authors, so check the
author in the summary row. A result on one platform or XPerl version does
not establish compatibility on another. New local install results appear in
these pages only after their receipts are reviewed, imported, and committed.

From a local checkout, search the summary with `rg -n 'Distribution-Name'
status/SUMMARY.md status/UNRESOLVED.md`.

Failed observations can contain a `triage` assessment. The unresolved page
shows its disposition: `unsupported-platform`, `obsolete-superseded`,
`upstream-broken`, or `unresolved`. Open the linked `status.json` for the
portable reason, public evidence links and any ordinary Perl controls.
Each control records the exact Perl version and build flags, including the
RC stack, threads, multiplicity, debugging, longdouble and quadmath.
A different failure or an older Perl control is not proof of current blead
behavior. Known XPerl and RC-stack incompatibilities remain repair targets.

These assessments belong to individual build observations, not every
release or platform of the distribution. The installer reuses a definitive
deferral only with the same source hash, XPerl build and patch digests.
Changing a patch or build configuration allows another attempt. Unresolved
assessments allow further investigation. Legacy release-wide manual triage
is preserved separately. Captured output limits appear as
`failure.resource_limit: "log"`, and `resource_limits` records the configured
memory and output caps. A guard stopping a command does not establish that
the module itself is broken.

## Review candidates

The [review queues](queues/README.md) hold modules selected for investigation
before we have a build result. A queue file can be passed directly to
`xperl-install install --from FILE`. The
[experimental class queue](queues/experimental-class-2026-11-08.txt) is an
initial set of candidates found through a CPAN source search. Record actual
build results in `data/`; a source match alone is not a failure.

## Browse XS and C fixes

Open [status/XS-PATCHES.md](status/XS-PATCHES.md) to find registered patches
that change `.xs`, `.c`, `.h`, or `.inc` files. Each row links the exact
release, patch, and matching validation evidence. The generated
`status/XS-PATCHES.json` carries the same information for tools. Run
`bin/build-xs-index` after registering a patch that touches native source;
`bin/build-xs-index --check` verifies that the catalog is current.

Author consent for upstream XPerl patches and the review queue are described
in [AUTHOR_POLICY.md](AUTHOR_POLICY.md). Author records stay in repository 0
when distribution data is sharded.

Use [PRIORITIZATION.md](PRIORITIZATION.md) and `bin/river-priorities` to rank
candidate ports by their River of CPAN reach alongside local XPerl build
status. This report is optional and separate from installation.
