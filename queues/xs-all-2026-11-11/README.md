# CPAN XS distribution survey

This survey tracks 3,069 distribution names whose latest MetaCPAN releases
have a file ending in `.xs`. It follows the completed River top-500 and
Debian Popcon top-100 work. The source-file criterion includes optional XS
implementations and XS test fixtures, and misses extensions shipped only
as generated C or through other mechanisms. It is an investigation list,
not a claim that every entry builds XS or works on this operating system.

The 2026-11-11 inventory starts with:

| Classification | Distributions |
| --- | ---: |
| Successful XPerl build already recorded | 285 |
| Bundled with XPerl | 31 |
| Explicitly deferred | 3 |
| Queued for installation or renewed investigation | 2,750 |
| Total | 3,069 |

The successful records span recorded platforms and build configurations.
They do not validate every profile. The three deferrals preserve earlier
decisions: B-C is out of date with blead, Gtk-Perl is obsolete, and
Example-XS-FasterHashes is an intentionally problematic example.
CPAN `Example::*` candidates are outside the repair campaign unless
explicitly requested. They may be demonstrations or intentional failures.
The installer test suite's local `Example::*` fixtures are unrelated and
continue to test installer behavior.

## Run the pending queue

Use an installed XPerl and its own prefix. Set `ports`, `prefix` and `work`
to the registry checkout, interpreter prefix and a new work directory:

```sh
"$prefix/bin/perl" "$prefix/bin/xperl-install" install \
  --registry "$ports" --prefix "$prefix" --workdir "$work" \
  --from "$ports/queues/xs-all-2026-11-11/install.txt" \
  --jobs 4 --repair-jobs 1 --agent codex \
  --phase-memory-mb 2048 --phase-log-mb 32 \
  --repair-timeout 600 --repair-interval 10 --publish auto
```

The built-in Codex adapter defaults to `gpt-6.1-sol` with high effort. The
agent is optional. Other configured providers use the same repair protocol.
Ordinary builds and publication continue without invoking AI unless a
repair is needed. Native dependencies and incompatible interpreter or
operating-system requirements may need human follow-up. A Linux result
does not establish Windows, macOS or another build-profile compatibility.

To stop gracefully or resume the saved queue:

```sh
"$prefix/bin/perl" "$prefix/bin/xperl-install" stop --workdir "$work"
"$prefix/bin/perl" "$prefix/bin/xperl-install" install --resume --workdir "$work"
```

Resume retains the selected interpreter, worker limits and agent settings.
An explicit `--phase-memory-mb` or `--phase-log-mb` on resume overrides a
saved limit. Memory limits are per build process, not an aggregate budget.
Keep the interpreter's build and installation prefix together. Do not mix
XS libraries from different builds.

## Selection and results

[inventory.json](inventory.json) preserves the original scope, provider
mapping and starting classifications. [install.txt](install.txt) contains
the pending targets, ordered first by Debian Popcon installed-package rank
when mapped, then by downstream counts from the saved River snapshot.
A source match does not establish a failure.

Each mapped entry records its Debian package, installation count and rank.
The verified top-100 mapping is reused. Other `lib*-perl` package names
are matched to a unique distribution name after ignoring punctuation and
case. Ambiguous names remain unranked. When several packages map to one
distribution, the most-installed package supplies its rank; their counts
are not added. This mapping is a prioritization aid that can be reviewed.

The installer gives shared prerequisites the earliest target's priority,
including prerequisites discovered during configuration. Dependencies must
still finish before their dependents, and four workers can run independent
releases concurrently. The order is a preference among runnable releases.

Module targets use the canonical CPAN package index. Public main-module
metadata is accepted only when that module's indexed archive matches the
selected release. Forty-six names do not map directly by archive naming
convention; their latest-release metadata supplies exact CPAN archive
targets instead. The installer validates each archive path and contents.
Unsupported archive formats, unavailable sources or unusable metadata are
reported as resolution failures without stopping independent targets.

The survey used MetaCPAN release and file aggregations, filtered to
`status: latest` and file names matching `*.xs`. Their intersection contains
3,069 names out of 42,047 latest-release distribution names, or 7.3%.
The queue is a snapshot. A later CPAN index may resolve a module target to
a newer release; exact archive targets remain fixed.

The installer records build observations and reusable repairs in the
normal author/distribution records under `data/` and publishes completed
results. Its final JSON records request-level resolution errors and gives
a resume command for incomplete work. Preserve those errors in the survey
review rather than counting them as successful tests. The starting
inventory is not a live build-status dashboard.

The interrupted first pass reached a prompt loop in `GOZER/mod_perl-1.31`.
Its [review](../../data/73/GOZER/mod_perl/REVIEW.md) records why this Apache 1
binding is deferred. The installer now caps captured command logs and can
limit build-process data memory. Known XPerl and RC-stack defects remain
repair targets. Other failures need triage against platform requirements,
upstream reports and ordinary Perl controls with exact versions and build
flags. Do not spend repairs rewriting obsolete packages or removing their
legitimate platform restrictions.
