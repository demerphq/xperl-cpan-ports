# Build status records

The importer at bin/import-receipts reads completed installer receipts into
distributions/<Distribution>.json. Each observation records the CPAN archive,
source hash, requested module, distribution release version, XPerl version,
selected patch set, build phases, and test count when available. The receipt
content hash identifies an observation, so importing the same cache again
does not duplicate it.

The importer derives the distribution release version from the CPAN archive.
A module can have a different version from its containing distribution; in
that case the record also includes module_version.

SUMMARY.md shows the latest observation for each release, source hash, and
XPerl version. UNRESOLVED.md lists combinations whose latest observation
failed. Prior failed observations remain in the distribution JSON after a
successful retry.

The importer stores no local prefix, work directory, command paths, or full
logs. The original installer receipts and logs remain in the local cache for
detailed diagnosis. Status is observational evidence; patch selection uses
the separate distributions/<Distribution>/index.json files.
