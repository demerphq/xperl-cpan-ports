# Registry sharding design

The current `xperl-cpan-ports` repository is repository 0: the permanent
bootstrap location. Its root publishes a small configuration file that
identifies every active data repository. A client fetches repository 0 first,
reads that configuration, and then selects one data repository for a resolved
CPAN author and distribution pair. Installation without the registry remains
possible.

Start with one active repository, repository 0. Allow the active count to grow
to eight if needed. Repository IDs are consecutive integers from zero to
`count - 1`. The root `registry.json` records the layout version, active
count, local checkout path for each ID, and the hash algorithm and seed
identifiers. Repository 0's path is `.`. Future repository entries can
include their remote URL and pinned revision for fetching. Repository 0's
revision is the revision from which the client read `registry.json`; it
cannot pin itself inside the same commit. A client rejects unknown algorithms
or layout versions. Repository 0 remains the bootstrap location even if a
distribution's data later moves to another repository.

The repository shape is:

```text
xperl-cpan-ports/                    # repository 0
  registry.json                      # bootstrap configuration
  recipes/<recipe-id>.md             # shared migration guidance
  data/<prefix>/<Author>/<Distribution>/
    index.json
    status.json
    patches/<patch>.patch
    evidence/<record>.json

xperl-cpan-ports-1/                  # only when repository 1 is activated
  data/<prefix>/<Author>/<Distribution>/
    index.json
    status.json
    patches/<patch>.patch
    evidence/<record>.json
```

## Release resolution and placement

When the caller supplies a module name without an author, resolve it through
the CPAN index first. The index identifies the default release and its
author. An explicit author and distribution pair selects that author's
release instead. Do not guess an author from a distribution name alone when
the CPAN index does not identify a release.

Use the canonical CPAN author ID and distribution name from the resolved
release as the placement key. Normalize the author ID to uppercase and check
that it agrees with the author in the CPAN archive path. Preserve the
distribution name's canonical case. Separate the two components with a
single slash, then encode the result as UTF-8 bytes:

```perl
my $key = Encode::encode('UTF-8', "$author/$distribution");
my $repository = builtin::jumphash_string($key, $active_count);
my $digest = builtin::siphash_2_4($key, "\0" x 16);
my $prefix = unpack 'H2', $digest;
```

For example, `ALICE/Example-XS` and `BOB/Example-XS` can select different
repositories and prefixes. All releases by one author of one distribution
share a location.

`jumphash_string` uses SipHash-2-4 with an all-zero 16-byte key, followed by
jump consistent hash. The prefix is the first byte of that same SipHash
result, rendered as two lowercase hexadecimal digits. These fixed choices
are part of the layout format. The prefix does not depend on the number of
repositories, so adding a repository changes only the selected repository
for the author and distribution pairs that jump hash remaps.

Within a data repository, keep each author's distribution index, patches,
evidence, and status together under one prefix:

```text
data/<prefix>/<Author>/<Distribution>/index.json
data/<prefix>/<Author>/<Distribution>/patches/<patch>.patch
data/<prefix>/<Author>/<Distribution>/evidence/<record>.json
data/<prefix>/<Author>/<Distribution>/status.json
```

The author ID and distribution name are validated as safe path components.
There are 256 stable prefix directories per repository. The first byte of a
fixed SipHash digest spreads author and distribution pairs through those
directories without tying the directory shape to the repository count.

Each author-specific index retains the original CPAN archive path, version,
and SHA-256 source digest for every release. A name and version alone do not
identify an archive. Two authors may publish the same distribution name and
version, but their records live in different author directories. Patch
selection still requires the exact CPAN path and source digest described in
[FORMAT.md](FORMAT.md). Recipes can remain shared documentation at the root
of repository 0; a patch set refers to a recipe by ID.

## Growth and migration

Changing the active count changes placement for some distributions. Before
publishing a new configuration, copy each affected author and distribution
directory to its new repository and verify the index, patch digests,
evidence, and status. Publish a pinned revision for every destination, then
atomically publish the new configuration in repository 0. Keep old revisions
available for clients holding an earlier configuration. A configuration
revision and its repository revisions form one registry snapshot for receipts
and review.

The original flat `distributions/` and `status/distributions/` records were
moved to this layout after the installer and receipt importer gained support
for it. Index content still uses the matching rules in [FORMAT.md](FORMAT.md).
