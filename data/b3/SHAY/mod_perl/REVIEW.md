# mod_perl 2.0.13: installed with threaded shared-library RC XPerl

This distribution entered the compatibility queue through the explicit
`APR` target in the hash-change search batch. It was not pulled in by
Catalyst or Task::Kensho.

The selected consolidated patch preserves the original CPAN release and
contains these repairs:

- On XPerl, reserve hash capacity with `hv_ksplit` and replace private
  bucket-chain lookup with `hv_fetch_ent`.
- With `PERL_RC_STACK`, give direct native callbacks a separate non-RC
  stack. This covers configuration constructors, metadata methods, merge
  handlers, request callbacks and authentication callbacks.
- Let Apache-Test resolve relative module includes through apxs SYSCONFDIR
  when ServerRoot and PREFIX are unavailable. This adapts Debian's existing
  fix, with its source linked in the patch and evidence.
- Guard Apache authentication test directives by their owning modules.
- Distinguish `APR::Error` from core exceptions by class, rather than treating
  every reference in `$@` as an APR exception.

The RC repair is guarded by `PERL_RC_STACK` alone. Hash-layout adaptations
use `XPERL_VERSION` and preserve ordinary Perl's existing paths. The generated
method lookup table is rebuilt by configuration, not included in the patch.

## Validated profile

Installed XPerl v5.45.5, commit
`8903238ce74fc124ec407b8342791ef73253f988`, x86_64 Linux, GCC 13.3.0,
ithreads, multiplicity, shared libperl, `PERL_RC_STACK`, no debugging,
double NV, without longdouble or quadmath. Tests use `PERL_DESTRUCT_LEVEL=2`.

- Main Apache runtime suite: 246 files, 2995 tests, pass.
- ModPerl::Registry: 21 files, 39 tests, pass.
- Apache-Test ServerRoot regression: seven checks pass independently.
- Apache::Reload: no tests run because optional HTML::HeadParser is absent.

Other tests skip optional Perl or Apache modules, or require a different
MPM. Those paths are not validated. Ordinary Perl, debugging XPerl,
longdouble, quadmath and other operating systems have not been tested with
this patch. Earlier unthreaded and static-library failures remain as
separate observations and do not describe the passing shared-library build.

## Installation layout

Perl modules install into the selected interpreter's normal site library.
Apache-specific headers and the DSO use mod_perl's documented staging option:

```toml
[install.configure_args]
"SHAY/mod_perl" = ["MP_AP_DESTDIR={prefix}/apache"]
```

On this Linux Apache layout, that places native files beneath
`{prefix}/apache/usr/include/apache2` and
`{prefix}/apache/usr/lib/apache2/modules`. These paths are configuration,
not part of the portable patch. The staged module is not activated in the
system Apache server.

Use a Perl embedding library suitable for the host MPM and shared-object
linker. The ordinary unthreaded or non-PIC static libperl build is not an
interchangeable substitute. See `embedding-build-profile-v1` and the other
recipes linked from `index.json`.
