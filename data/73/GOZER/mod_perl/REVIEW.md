# mod_perl 1.31: obsolete Apache 1 integration

The XS survey selected `GOZER/mod_perl-1.31.tar.gz` through `Apache::src`.
This is the Apache 1 binding. It is separate from the modern
`SHAY/mod_perl-2.0.13` distribution already validated with XPerl.

This release's `INSTALL` requires Apache 1.3.6 or later in the 1.3 family.
When no Apache source tree is found, `Makefile.PL` repeatedly asks for one.
Its retry loop accepts the default missing directory on EOF and never
terminates. The survey's configure phase timed out after 3600 seconds.
Its output loop generated an exceptionally large log before the survey
ended through an out-of-memory kill. The retained local log contains its
beginning and end, with cleanup metadata. Full logs are not registry data.

The assessment is `obsolete-superseded`, supported by Apache's documentation:

- [mod_perl downloads](https://perl.apache.org/download/index.html) identifies
  mod_perl 1.31 as the Apache 1.3 binding and mod_perl 2 as the Apache 2 binding.
- [Apache 1.3 support status](https://httpd.apache.org/security/vulnerabilities_13.html)
  says that Apache 1.3 is no longer maintained and advises upgrading.
- [The original CPAN release](https://metacpan.org/release/GOZER/mod_perl-1.31)
  identifies the exact distribution assessed.

The failed result and new assessment are retained in `status.json`, with
the exact source digest and XPerl v5.45.5 build configuration. No ordinary
Perl control was run, and this assessment does not claim a Perl or XPerl
compatibility defect. We are not rewriting this release for Apache 2 or
installing an obsolete Apache 1 stack. Use modern mod_perl for Apache 2.
