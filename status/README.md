# Build status records

The importer at bin/import-receipts reads completed installer receipts into
`data/<prefix>/<Author>/<Distribution>/status.json`. Each observation records
the CPAN archive, source hash, requested module, distribution release
version, XPerl version, platform, selected patch set, build phases, and test
count when available. The receipt content hash identifies an observation.
Importing the same cache again does not duplicate it.

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
