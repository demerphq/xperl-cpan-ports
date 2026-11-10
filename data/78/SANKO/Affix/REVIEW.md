# Affix v1.4.0: ordinary debug RC shutdown failure

The callback-member repair selected by `PERL_RC_STACK` passes the full suite
on installed RC XPerl v5.45.5, commit
`8903238ce74fc124ec407b8342791ef73253f988`: 58 files, 390 tests.

The same registered patch was replayed from the original release archive
with installed ordinary Perl v5.45.4, `PERL_RC_STACK`, `DEBUGGING` and
`DEBUG_LEAKING_SCALARS`, using `PERL_DESTRUCT_LEVEL=2`. All assertions in
the callback-member regression, `t/091_cb_struct_member.t`, pass. The full
suite fails because `t/999_marshaller_2.t` aborts during destruction, after
its 18 top-level tests pass. That is a failed validation, not a successful
build or installation.

The debugger trace reaches `hv_iterinit(affix->variadic_cache)` in
`_affix_destroy`, called by `Affix_cv_free` during `perl_destruct`. The hash
pointer no longer has type `SVt_PVHV`, triggering the debug assertion in
`Perl_hv_iterinit`. The cache is a native structure's `newHV()` allocation.
Its ownership and lifetime during global destruction need investigation.
Do not work around this by disabling destruction checks or merely skipping
the hash iterator.

The important part of the trace, with host paths and addresses omitted, is:

```text
Perl_hv_iterinit: Assertion `SvTYPE(hv) == SVt_PVHV' failed
_affix_destroy                 lib/Affix.c:2296
Affix_cv_free                  lib/Affix.c:2335
Perl_mg_free_struct
Perl_mg_free
Perl_sv_clear
Perl_sv_free2
Perl_sv_clean_all
perl_destruct
```

The ordinary-Perl control uses its own installation prefix and builds all
XS dependencies for that interpreter. The existing Data-Printer registry
patch is required for its RC-sensitive reference-count reporting tests;
with that patch, all 695 dependency tests pass before Affix is tested.

This failure has not been established on ordinary non-RC Perl, on a
non-debug ordinary RC build, or on a debug XPerl build. The current XPerl
pass does not prove the absence of a lifetime problem on those builds.
Keep the passing XPerl evidence and failed ordinary-Perl control separate.

The release metadata names
[sanko/Affix.pm](https://github.com/sanko/Affix.pm) as upstream. Consult that
repository's issues and recent lifetime fixes before implementing a repair.
The exact patch hashes and tested configurations are in this directory's
`evidence/` records.
