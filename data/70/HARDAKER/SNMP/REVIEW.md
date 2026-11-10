# SNMP 5.0404: correct headers, then review the library version

The latest CPAN release, SNMP 5.0404, was published on 2013-10-17. Its native
library counterpart is Net-SNMP 5.4.4. The current investigation uses the
system Net-SNMP 5.9.4.pre2 library on Linux.

## Registered repair

`current-perl-headers.patch` puts the running interpreter's `CORE` directory
ahead of the Perl headers reported by `net-snmp-config --cflags`. Without
this change, the system Perl 5.38 headers take precedence. That produced
`undefined symbol: PL_current_context` when loading the extension with an
unthreaded XPerl build.

This is a general Perl build fix, without an XPerl or RC-stack conditional.
It is separate from the problems caused by the old Net-SNMP API.

## Reproduced remaining failure

Fresh builds with only the registered patch configure and compile, but fail
to load with `undefined symbol: memdup`. This reproduces on both installed
Perl 5.44.0 and installed RC XPerl 5.45.5, commit
`8903238ce74fc124ec407b8342791ef73253f988`. Neither run installs SNMP.
The evidence record includes the complete XPerl build configuration.

The comparison explicitly sets the distribution's documented
`NETSNMP_DONT_CHECK_VERSION=1` opt-in to investigate the mismatch. The
registered patch does not disable the library version check. Without that
opt-in, the distribution can reject this library during configuration.

Net-SNMP's [binding documentation](https://www.net-snmp.org/docs/perl-SNMP-README.html)
recommends building its Perl modules together from the matching library
source. The [5.9.4 binding source](https://github.com/net-snmp/net-snmp/blob/v5.9.4/perl/SNMP/SNMP.xs)
contains relevant API updates. Prefer checking those updates before trying
to modernize this CPAN snapshot independently.

## Diagnostic follow-ups, not registered repairs

Local experiments changed the old three-argument `memdup` calls to
`netsnmp_memdup` and initialized both session structures with
`snmp_sess_init`. Those changes permit loading and session creation with
Net-SNMP 5.9.4. They are not included in the registered patch:

- Net-SNMP 5.4.4 has the old `memdup` API. Any replacement must preserve that
  supported library version, or declare and justify a new requirement.
- The old code zero-initializes sessions. Newer libraries require valid
  default message limits supplied by `snmp_sess_init`.
- Further testing with matching upstream MIB files and the installed
  `snmpd` and `snmptrapd` reaches callback crashes and test failures. A
  debugger traces one shutdown crash to `__snmp_xs_cb` fetching `ErrorStr`
  through an invalid session reference while `snmp_sess_close` runs during
  Perl destruction. Whether that crash also occurs with ordinary Perl has
  not been established.
- MIB, session, and bulkwalk tests need separate diagnosis. Some depend on
  old MIB definitions or network assumptions. Do not suppress them simply
  to obtain a successful installation.
- `SNMP.pm` unconditionally loads `NetSNMP::default_store`, but
  `Makefile.PL` comments out its `PREREQ_PM` entry. The comparison installed
  that dependency explicitly into each interpreter's own isolated prefix.
  Automatic dependency resolution needs a distribution metadata repair.

The separate `NetSNMP-default_store` registry entry includes the header fix
and a test repair for the library's larger default-store capacity. All 90
tests pass on both interpreters. Its MakeMaker test override uses the TAP
harness so printed failures produce a failing `make test` exit status.

SNMP remains unresolved. The header repair is useful independently, but its
presence in the registry is not a claim that the complete distribution
passes with Net-SNMP 5.9.4 or with every Perl build configuration.
