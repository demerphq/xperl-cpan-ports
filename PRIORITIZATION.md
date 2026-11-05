# Choosing CPAN port targets

MetaCPAN's [River of CPAN snapshot](https://github.com/metacpan/metacpan-river)
counts distributions that depend on each distribution directly (`immediate`)
and through other dependencies (`total`). The snapshot is published nightly
and keyed by distribution name, which matches this registry's status records.

Use river reach to find ports that may unblock many other distributions.
Start with a failed XPerl build if there is one, then test high-reach
distributions that have no observation. Within a similar reach, prefer a
distribution that is a dependency of a current XPerl target. A successful
observation is evidence for the recorded release and XPerl version only.

The report is separate from installation. It does not change CPAN resolution,
skip tests, or apply patches. Save a snapshot locally and run:

    curl -fsSL https://metacpan.github.io/metacpan-river/river.json.gz -o river.json.gz
    /path/to/xperl/bin/perl bin/river-priorities --river river.json.gz --limit 30

For the current web and data candidates:

    /path/to/xperl/bin/perl bin/river-priorities --river river.json.gz \
      --candidates priorities/web-and-data.txt --pending

The report shows the author of each latest local observation. When several
authors have published the same distribution name, that observation may not
belong to the CPAN index default. Resolve a module through the CPAN index
before treating a port as available for an ordinary install.

The full ranking includes Perl core and other already available
distributions. Use `--pending` to hide locally successful observations, or
pass `--candidates FILE` with one distribution name per line to rank a
curated set. `--pending` hides any distribution with a locally successful
observation, even if that observation is for an older release. The command
prints the snapshot hash so a decision can be reproduced. Do not commit the
nightly snapshot to the patch registry.

River reach is a prioritization signal, not a compatibility verdict. It
counts CPAN dependencies rather than actual XPerl users, does not identify
the current CPAN release version, and does not measure the cost of a port.
Keep the installer receipt and test result as the evidence for each attempt.
