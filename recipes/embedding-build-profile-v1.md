# Match an embedding interpreter to its native host

An extension that embeds Perl in a server can need more than an ordinary
loadable XS module. mod_perl 2.0.13 exposes two distinct configuration
requirements when building a DSO for a threaded Apache MPM:

- The Perl interpreter must support ithreads when required by the MPM.
- Its embedding library must be suitable for linking into a shared object.
  On affected ELF platforms, a non-PIC `libperl.a` fails with relocation
  errors even when the extension's own objects were compiled with `-fPIC`.

Read the failing compiler or linker command and inspect the installed
interpreter's `Config`. Distinguish missing headers, a wrong Perl include
path, a missing library and an incompatible static embedding library.
Do not treat all link failures as missing system packages or XS API bugs.

Record threads, multiplicity, `useshrplib`, debugging, `PERL_RC_STACK`,
longdouble and quadmath in the build evidence. Static and shared libperl
profiles are distinct even when their ordinary compiler flags match.
A passing shared-library build does not validate a static-library build.

In normal installer operation, report the incompatible interpreter as a
user action with the required capabilities. The user can select a suitable
installed interpreter or host configuration. Do not silently patch the
interpreter, switch builds, disable the RC stack or remove debugging flags.
During authorized core development, a separately installed Perl build can
provide that profile. Keep each interpreter's XS libraries separate.

## Stage native host files without a system installation

An extension may install headers or server modules outside Perl's library
layout. Use its documented staging option. mod_perl's `MP_AP_DESTDIR`
prepends a destination to Apache-specific paths without redirecting its
normal Perl module installation. It can be supplied through the installer's
author-qualified `configure_args` configuration:

```toml
[install.configure_args]
"SHAY/mod_perl" = ["MP_AP_DESTDIR={prefix}/apache"]
```

Keep staging paths in user configuration and local receipts, never in the
portable source patch. Installing a staged module does not activate it in
the system server. Server configuration and deployment are separate steps.
Test with the same installed interpreter and native host used to build it.
