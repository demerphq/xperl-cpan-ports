# Registry sharding design

The current `xperl-cpan-ports` repository is repository 0: the permanent
bootstrap location. Its root will publish a small configuration file that
identifies every active data repository. A client fetches repository 0 first,
reads that configuration, and then selects one data repository for a resolved
CPAN distribution. Installation without the registry remains possible.

Start with one active repository, repository 0. Allow the active count to grow
to eight if needed. Repository IDs are consecutive integers from zero to
`count - 1`. The proposed root `registry.json` records the layout version,
active count, repository URL for each ID, pinned revisions for repositories
other than 0, and the hash algorithm and seed identifiers. Repository 0's
revision is the revision from which the client read `registry.json`; it
cannot pin itself inside the same commit. A client rejects unknown algorithms
or layout versions. Repository 0 remains the bootstrap location even if a
distribution's data later moves to another repository.

The target repository shape is:

```text
xperl-cpan-ports/                    # repository 0
  registry.json                      # bootstrap configuration
  recipes/<recipe-id>.md             # shared migration guidance
  data/<prefix>/<Distribution>/
    index.json
    status.json
    patches/<patch>.patch
    evidence/<record>.json

xperl-cpan-ports-1/                  # only when repository 1 is activated
  data/<prefix>/<Distribution>/
    index.json
    status.json
    patches/<patch>.patch
    evidence/<record>.json
```

## Distribution placement

Resolve a module through CPAN metadata before looking in the registry. Use
the CPAN distribution name, in its canonical case, encoded as UTF-8 bytes as
the placement key. All releases of that distribution share one location:

```perl
my $key = Encode::encode('UTF-8', $distribution);
my $repository = builtin::jumphash_string($key, $active_count);
my $digest = builtin::siphash_2_4($key, "\0" x 16);
my $prefix = unpack 'H2', $digest;
```

`jumphash_string` uses SipHash-2-4 with an all-zero 16-byte key, followed by
jump consistent hash. The prefix is the first byte of that same SipHash
result, rendered as two lowercase hexadecimal digits. These fixed choices
are part of the layout format. The prefix does not depend on the number of
repositories, so adding a repository changes only the selected repository
for the distributions that jump hash remaps.

Within a data repository, keep the distribution's index, patches, evidence,
and status together under one prefix:

```text
data/<prefix>/<Distribution>/index.json
data/<prefix>/<Distribution>/patches/<patch>.patch
data/<prefix>/<Distribution>/evidence/<record>.json
data/<prefix>/<Distribution>/status.json
```

The distribution name is validated as a safe path component before use.
There are 256 stable prefix directories per repository. The first byte of a
fixed SipHash digest spreads names through those directories without tying
the directory shape to the repository count.

The distribution index retains the original CPAN archive path, version, and
SHA-256 source digest for every release. A name and version alone do not
identify an archive: two authors may publish releases with the same
distribution name and version. Those releases live in the same distribution
index as separate entries, and patch selection still requires the exact
CPAN path and source digest described in [FORMAT.md](FORMAT.md). Recipes can
remain shared documentation at the root of repository 0; a patch set refers
to a recipe by ID.

## Growth and migration

Changing the active count changes placement for some distributions. Before
publishing a new configuration, copy each affected distribution directory
to its new repository and verify the index, patch digests, evidence, and
status. Publish a pinned revision for every destination, then atomically
publish the new configuration in repository 0. Keep old revisions available
for clients holding an earlier configuration. A configuration revision and
its repository revisions form one registry snapshot for receipts and review.

The current flat `distributions/` and `status/distributions/` paths remain
the version 1 layout. Move them only when the installer and receipt importer
can read the new configuration and path scheme. This document defines the
target layout; it does not silently change existing registry behavior.
