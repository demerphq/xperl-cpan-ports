# Contributing a CPAN port

Start from the unmodified CPAN release archive. Record its distribution name,
version, CPAN path, and SHA-256 digest. Reproduce the failure with a named
XPerl build before changing the source. Check whether the failure is specific
to XPerl rather than a missing dependency or a platform problem.

Make the smallest source patch that fixes the incompatibility. Prefer a change
that works on ordinary Perl too. When an XS implementation must differ, use
`#ifdef XPERL` after including Perl headers. Keep patch paths relative to the
release root and usable with `patch -p1`.

Build and run the distribution's tests with XPerl after applying the patch.
Test with ordinary Perl when practical. Add or update the distribution index
and include the patch's SHA-256 digest. Put a test record under `evidence/`.
If the issue is likely to recur, add a recipe that explains the general fix
without assuming this distribution's source layout.

Submit the patch, index change, evidence, and any recipe for review together.
An installer or AI agent may prepare these files, but it must not publish them
automatically. A reviewer checks the upstream identity, patch scope,
applicability interval, reproducibility, and compatibility claims before the
registry accepts them.
