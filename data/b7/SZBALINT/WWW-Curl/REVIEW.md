# WWW-Curl 4.17 repair and registry-only replay

The repair is registered against `SZBALINT/WWW-Curl-4.17.tar.gz`:

- Source SHA-256:
  `52ffab110e32348d775f241c973eb56f96b08eedbc110d77d257cdb0a24ab7ba`
- [Patch](patches/repair-v5.45.5-4.17-23f09986e570.patch), SHA-256:
  `23f09986e57029801f618b94201523324ddfc2d8e761e47e5a638a4e6eb622e3`
- [Validation evidence](evidence/repair-v5.45.5-4.17-23f09986e570.json)
- [Build observations](status.json)

## Source changes

The configure script finds compiler-default libcurl headers when
`curl-config` omits their directory. It uses the configured compiler and
flags for preprocessing, keeps MakeMaker installation arguments separate
from the optional header directory, and rejects function-like macros and
empty guards when generating integer constants.

The XS uses libcurl's public handle typedefs and recognizes the current
multi-header guard. These are general libcurl compatibility fixes. They
contain no XPerl-specific branch or RC-stack ownership change. The patch
includes the packaged Easy.pm and Share.pm export tables produced during
the original repair build. Makefile.PL regenerates those tables from the
target machine's headers during configuration.

Cookie assertions use a temporary Netscape cookie file and compare the
exact seeded entry. They no longer assume that a public website sends a
cookie. The added local-file tests cover binary transfers, Perl callbacks,
duplicated handles, multi-handle completion, forms and share construction.
The original network tests and their existing optional-test switches are
preserved. See the linked recipes for recurring discovery and fixture issues.

The original agent checked upstream reports and recorded the applicable
origins in the evidence, including
[Debian bug 852853](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=852853)
and [upstream PR 24](https://github.com/szbalint/WWW--Curl/pull/24).

## Registration recovery

The initial repaired build passed and installed, but registration rejected
the patch because it removed an upstream README example containing a home
directory. The installer now checks added lines for new home paths.
Recovery retained the original receipt and recorded a registration retry
with the original phase results and timings. It did not claim a new build.

A separate clean replay used the original CPAN archive, the registered
patch, the installed XPerl interpreter and ordinary installer workflow,
with no repair agent. Configuration, compilation, tests and installation
all passed. The full suite passed 856 tests in 23 files. Existing optional
upload, slow-leak and metadata test skips remain as reported by the suite.

Validation used XPerl v5.45.5, core commit
`8903238ce74fc124ec407b8342791ef73253f988`, Linux x86-64, GCC 13.3.0,
libcurl 8.5.0, PERL_RC_STACK, no threads, no multiplicity, no debugging,
double NV and static libperl. Build ID:
`28cd83709959c0b00ef653a383ad362f0cca8d9b357b92fef795df2c54651583`.
The replay used a 2048 MiB per-process build data limit and a 32 MiB
captured-output cap. Other platforms, ordinary Perl, threads, debugging,
longdouble and quadmath have not been validated by this repair.
