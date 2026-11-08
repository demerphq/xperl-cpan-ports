# Build status records

The importer at bin/import-receipts reads completed installer receipts into
`data/<prefix>/<Author>/<Distribution>/status.json`. Each observation records
the CPAN archive, source hash, requested module, distribution release
version, XPerl version, platform, selected patch set, build phases, and test
count when available. The receipt content hash identifies an observation.
Importing the same cache again does not duplicate it.
Results with the same recorded build facts are stored once even if separate
receipts have different IDs or timestamps. The first observation stays in
place. A different result for the same release, XPerl version, and platform
is a new observation; a later return to the earlier result records that
state change. When two observations share a timestamp, the one already
recorded stays first, so a repeat imported in the same second cannot replace
it.

`--receipt FILE` imports specific receipts. With `--record-only`, only those
receipts' distribution records are read and updated, and this page's
SUMMARY.md and UNRESOLVED.md are left for a later `--rebuild`.

The importer derives the author and distribution release version from the
CPAN archive.
A module can have a different version from its containing distribution; in
that case the record also includes module_version.

SUMMARY.md shows the latest observation for each author, release, source
hash, XPerl version, and platform. UNRESOLVED.md lists combinations whose
latest observation failed. Prior failures remain in the status record after a
successful retry.

The importer stores no local prefix, work directory, command paths, or full
logs. The original installer receipts and logs remain in the local cache for
detailed diagnosis. Status is observational evidence; patch selection uses
the separate `index.json` in the same author and distribution directory.

`bundled-with-xperl.json` records distribution names shipped in the XPerl
source tree for the stated XPerl version. It includes XPerl additions as well
as ordinary Perl core distributions. This is source inventory, not a CPAN
build or test observation; platform-specific availability can differ.

The platform comes from the installer receipt: a key of the operating system
and interpreter architecture name (for example `linux/x86_64-linux` or
`darwin/darwin-2level`), with the OS version, compiler, make program, thread
and 64-bit support, and XPerl commit. Results from different platforms are
kept as separate rows, so a failure on one host does not hide a success on
another. Observations imported before receipts recorded the platform show
`unrecorded` until a platform is assigned with
`bin/import-receipts --rebuild --assume-platform OS/ARCHNAME`, which only
affects observations that have no platform. A result describes the platform
it was observed on; it is not a claim for other platforms.

New receipts include a build identity and its configuration, including the
reference-counted stack, threads, debugging, long double, and quadmath.
The summary separates results with different build identities. Older receipts
without a build identity stay separate; their missing configuration is unknown.
The summary shows the patch digests tested by each result. A successful result
for an older digest does not establish that a newer patch passed on that build.
