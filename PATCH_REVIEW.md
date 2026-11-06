# Patch review

This review classifies the 26 patch sets retained on 2026-11-06 by the code
they change. Classification is based on patch inspection. It does not claim
that each patch is still needed with the installed XPerl. A clean CPAN build
with the installed interpreter is the test for removing a patch.

| Class | Distributions | Review result |
| --- | --- | --- |
| XPerl exception representation and propagation | Capture-Tiny, Params-Validate, DBIx-Class, IO-Async, POE-Test-Loops, Test-Exception, POE, libwww-perl, Catalyst-Runtime, Plack, Moose, Syntax-Keyword-Try, Future-AsyncAwait, Test-Trap, Moo, Template-Toolkit | Keep pending clean-release retests. Several patches change stringification or assertions, so their exact behavior should be checked against structured exception diagnostics. |
| XPerl parser or hash XS interfaces | XS-Parse-Keyword, XS-Parse-Sublike, Sereal-Encoder | Keep. These use `XPERL_VERSION` around changed internal APIs. Retest against each supported XPerl version. |
| XPerl class object representation | Data-Printer | Keep. Review the field conversion against the current class-object API before extending its version range. |
| Output-sensitive test fixtures | Devel-NYTProf | Retest unpatched with the current installed XPerl. This patch filters profile rows and needs closer scrutiny. |
| Test environment assumptions | Net-DNS, YAML-PP, ack, Mojolicious | These fixes do not require XPerl changes. Keep only where clean-release tests fail under the installer's normal CPAN environment. Tests should establish the environment they require. |
| General XS correctness | HTML-Parser | Keep pending confirmation and upstream submission. Its hash value lifetime fix is useful on ordinary Perl too. |

Pod-Parser's test patch was removed. The clean 1.67 release passed all 25 tests
and installed using the installed Perlbrew XPerl, without a registry patch.
The earlier failure came from the installer's child process inheriting the
Perl source checkout's `lib/` path. The successful unpatched observation is
in its `status.json` record.

Test-Differences' Dumper output patch was also removed. The clean 0.73
release passed its full test suite with the installed XPerl after the
Data::Dumper behavior was corrected: 17 files, 49 tests.

The installer must run with an installed XPerl for these retests. The local
`prefix/lib/perl5` is provided through `PERL5LIB`. Changes to XPerl itself are
a development option when a real interpreter defect is found; they are not
part of the installer or a requirement for end users.
