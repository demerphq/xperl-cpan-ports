# Author and distribution records

Each CPAN author and distribution pair has one directory under the fixed
SipHash prefix. Keep its `index.json`, `status.json`, patches, and evidence
there. The original CPAN archive path and source digest remain in the index
so patch selection identifies an exact upstream release.

See [SHARDING.md](../SHARDING.md) for placement and [FORMAT.md](../FORMAT.md)
for index matching rules.
