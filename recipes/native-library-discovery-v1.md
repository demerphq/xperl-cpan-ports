# Discover native headers through the configured compiler

## Symptom and cause

A configure script reports that a native header is missing even though
the compiler can include it. A library's config tool can omit directories
in the compiler's default search path. A fixed directory list can miss
multiarch locations. This is a build-discovery problem, not evidence of
an XPerl or RC-stack defect.

WWW-Curl 4.17 assumes `curl-config --cflags` contains an `-I` directory
for `curl/curl.h`, then falls back to guessed paths. On the validated Linux
host, libcurl's header directory is a compiler default and is omitted from
that output. The original configure script fails before XS compilation.

## Repair

Check that the native development package is installed first. If the header
is genuinely absent, report the dependency instead of changing the source.
Preserve existing discovery paths. Use the interpreter's configured
compiler and flags to preprocess a small source containing the required
include, and inspect its line markers to locate the header. Keep compiler
arguments as separate argv elements and preserve native-library flags.
Avoid hardcoding the current machine's multiarch directory.

Use the same configured compiler when extracting constants. Match
object-like integer macros rather than every name beginning with the
library prefix. Function-like macros and empty header guards are not
integer constants. Inspect the actual header when a helper macro changes.
Do not treat every newly encountered name as a public numeric constant.

Keep optional configure arguments separate from MakeMaker options such as
`INSTALLDIRS=site`; an installation option is not a header directory.
Preserve public library typedefs rather than guessing their underlying
struct names. Ordinary Perl needs these fixes too, so they need no
XPerl-specific conditional.

## Validation and limits

Use a clean original archive and the recorded patch through an installed
interpreter. Reconfigure before compiling so generated constant tables
reflect the target headers. Verify local operations and Perl callbacks,
then run the full test suite and report any network-related failures or
existing skips explicitly.

WWW-Curl 4.17 passes 856 tests in 23 files and installs in a clean
registry-only replay on XPerl v5.45.5 with PERL_RC_STACK, GCC 13.3.0 and
libcurl 8.5.0 on Linux x86-64. No ordinary Perl or other platform control
was run. Preprocessor flags and line-marker formats vary by compiler.
The validated implementation does not establish support for every compiler.
