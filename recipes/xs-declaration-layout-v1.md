# Keep XS declarations at the start of the line

## Symptom and cause

Recent ExtUtils::ParseXS versions can reject an indented XS function
declaration with a message such as `Cannot parse function definition`.
Sys::CpuAffinity 1.12 has this problem in the Solaris processor-bind
fragment. Its build combines platform fragments into one XS file, so the
bad declaration prevents a Linux build too.

This is a general XS syntax issue, independent of XPerl's hash layout and
`PERL_RC_STACK`. Inspect the diagnostic's source line and the original
fragment before editing a generated XS or C file.

## Preferred repair

Move the XS function name to the beginning of its line. Preserve the
function signature, return type, argument declarations and CODE block.
Apply the repair to the source fragment that the build combines, rather
than publishing a generated file containing one host's platform choices.
No XPerl or RC-stack conditional is needed.

The registered Sys::CpuAffinity 1.12 repair removes two leading spaces
before `xs_getaffinity_processor_bind`. Upstream
[PR 2](https://github.com/rzr/Sys-CpuAffinity/pull/2) reports the same
failure with xsubpp 3.61 on Fedora 44 and proposes the same source change.

## Validation

Build and run the distribution's tests with the installed interpreter.
The registered repair passes all 24 tests on Linux with XPerl v5.45.5,
`PERL_RC_STACK`, no threads and no debugging, using xsubpp 3.65.
This validates parsing the combined XS and the Linux implementation.
It does not validate the Solaris runtime or other operating systems.

Platform-selection probes may deliberately fail to compile when their
headers are absent. Do not treat every missing non-native platform header
as a host dependency. Check the final selected implementation and the
actual failed build command.
