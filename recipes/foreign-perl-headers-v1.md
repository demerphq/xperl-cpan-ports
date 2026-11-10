# Compile XS against the running interpreter's headers

## Symptom and cause

An XS extension compiles but cannot load, or uses an incompatible Perl ABI.
For example, SNMP 5.0404 loads with `undefined symbol: PL_current_context`
when Net-SNMP's build flags select a threaded system Perl's headers for an
unthreaded XPerl build.

External configuration programs can return Perl include directories left
over from their own builds. In Net-SNMP 5.9.4 on Debian-derived systems,
`net-snmp-config --cflags` can contain a system Perl `CORE` directory.
MakeMaker's usual `-I$(PERL_INC)` appears later in the compiler command, so
putting the correct directory in `INC` alone does not establish precedence.

This is a general XS build bug. It can affect ordinary Perl, threaded or
unthreaded interpreters, and different installed Perl versions. It does not
require an XPerl version or `PERL_RC_STACK` guard.

## Preferred repair

Inspect the actual compiler command and identify which `perl.h` is selected.
Put the target interpreter's `CORE` directory ahead of foreign Perl include
directories in the compiler flags. Preserve the external library's include
directories and other required flags. For MakeMaker with Unix compiler flags,
this can be expressed as:

```perl
# External library flags may include another Perl's headers.
$Params{CCFLAGS} = '-I"$(PERL_INC)" ' . $Params{CCFLAGS};
```

Apply this after selecting external flags, including environment overrides.
Use the platform's own flag conventions in non-Unix branches. Do not add
compatibility globals or change Perl's ABI to satisfy an extension compiled
against the wrong headers.

## Validation

Use a fresh source tree and an installed interpreter. Check the compiler
command for header precedence, then build, load, and test the extension.
When possible, repeat with an installed ordinary Perl whose headers differ
from the external library's recorded Perl. Keep a separate install prefix
for each interpreter build.

Distinguish this repair from unrelated library-version failures. The CPAN
SNMP 5.0404 bindings target Net-SNMP 5.4.4. Correcting their Perl headers does
not establish compatibility with the Net-SNMP 5.9 library API or its test
environment. Keep those failures visible in status and review notes.

Net-SNMP's [Perl binding guidance](https://www.net-snmp.org/docs/perl-SNMP-README.html)
recommends building its Perl modules together from a matching library source
release. Check that source before independently rewriting old CPAN bindings.
