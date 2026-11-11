# RC guard portability validation

These results validate the patches selected by `PERL_RC_STACK` without
requiring `XPERL_VERSION`. Each distribution's evidence names its exact
source and patch hashes. Historical patch files and evidence remain for
previous results, while `index.json` selects the new digest.

- RC XPerl: installed v5.45.5, commit `8903238ce74fc124ec407b8342791ef73253f988`,
  GCC 13.3.0, x86_64 Linux, no threads, no debugging, double precision.
- Ordinary RC Perl: installed v5.45.4, GCC 13.3.0, x86_64 Linux, no threads,
  `DEBUGGING` and `DEBUG_LEAKING_SCALARS`, double precision.
- Both lanes use `PERL_DESTRUCT_LEVEL=2`. Each interpreter has its own library
  tree. Per-build evidence records the remaining configuration details.

All 13 distributions pass on RC XPerl and ordinary debug RC Perl. Affix
needed a separate general lifetime repair after its callback-member fix:
native payloads now release their Perl values before the final SV sweep.
Its earlier failed control is retained against the earlier patch digest.

| Distribution | Version | RC XPerl | Ordinary debug RC Perl |
| --- | --- | --- | --- |
| [KSTAR/Hash-SharedMem](../data/28/KSTAR/Hash-SharedMem/index.json) | 0.007 | pass, 39800 tests | pass, 39796 tests |
| [LNATION/Colouring-In-XS](../data/d0/LNATION/Colouring-In-XS/index.json) | 0.13 | pass, 352 tests | pass, 352 tests |
| [LNATION/File-Raw](../data/1e/LNATION/File-Raw/index.json) | 0.19 | pass, 403 tests | pass, 403 tests |
| [LNATION/Horus](../data/17/LNATION/Horus/index.json) | 1.00 | pass, 209 tests | pass, 209 tests |
| [LNATION/Object-Proto](../data/07/LNATION/Object-Proto/index.json) | 1.04 | pass, 1627 tests | pass, 1563 tests |
| [SANKO/Affix](../data/78/SANKO/Affix/index.json) | v1.4.0 | pass, 394 tests | pass, 394 tests; [review](../data/78/SANKO/Affix/REVIEW.md) |
| [SMUELLER/Class-XSAccessor](../data/42/SMUELLER/Class-XSAccessor/index.json) | 1.19 | pass, 399 tests | pass, 399 tests |
| [SYBER/next-XS](../data/c7/SYBER/next-XS/index.json) | 1.0.8 | pass, 95 tests | pass, 95 tests |
| [VPIT/autovivification](../data/a8/VPIT/autovivification/index.json) | 0.18 | pass, 44417 tests | pass, 44417 tests |
| [XMATH/Data-Alias](../data/cc/XMATH/Data-Alias/index.json) | 1.30 | pass, 645 tests | pass, 643 tests |
| [XSAWYERX/Ref-Util-XS](../data/ed/XSAWYERX/Ref-Util-XS/index.json) | 0.117 | pass, 481 tests | pass, 478 tests |
| [YVES/Sereal-Decoder](../data/23/YVES/Sereal-Decoder/index.json) | 7.001 | pass, 86613 tests | pass, 84420 tests |
| [ZEFRAM/Params-Classify](../data/7f/ZEFRAM/Params-Classify/index.json) | 0.015 | pass, 4757 tests | pass, 4754 tests |

Data-Alias needs an additional RC repair in its compile-time check hooks.
Those hooks can run on a counted stack outside `XSPP_wrapped`. The repaired
source passes 643 tests on ordinary debug RC Perl and conventional Perl
v5.44.0, and 645 on RC XPerl. The difference includes interpreter-specific
test branches. See `refcounted-stack-custom-op-v1` for the pattern.

The existing Data-Printer patch passes all 695 tests on ordinary debug RC
Perl as an Affix dependency. Affix's new process-exit regression fails with
the earlier patch and passes with the lifetime repair. The revised patch
passes all 394 tests on conventional ordinary Perl v5.44.0 too.

Affix's revised patch separately passes on threaded RC XPerl with shared
libperl: 59 files, 386 tests, including its ithreads and shutdown tests.
The embedding test skips because its `-lperl` command cannot find the
shared library. This does not establish threaded coverage for the other
distributions. Debug XPerl, longdouble and quadmath have not been tested
by this exercise. Ordinary-Perl controls live in evidence; `status.json`
retains the normal installer results from XPerl.
