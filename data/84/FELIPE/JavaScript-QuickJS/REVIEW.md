# JavaScript::QuickJS 0.21: optional arguments and exception conversion

The River top-500 batch exposed a crash in `t/promise.t` on RC XPerl.
`Promise::then()` reads two arguments through `&ST(1)` even when the caller
omits them. Its XS declaration initializes defaulted C parameters without
adding stack entries. The repair passes a local array of those initialized
parameters to the converter. This is a general XS bug fix with no
interpreter-specific condition.

After that repair, the test reaches an exception-conversion issue. Under
`XPERL_VERSION`, the patch renders `XPerl::Exception` values as UTF-8 strings
at the JavaScript error boundary. Other exception objects retain the
existing conversion behavior. No private hash layout changes are involved.

Regression tests cover resolved and rejected promises with zero, one and
two callbacks, and verify that Perl text errors arrive as JavaScript
strings. All 203 tests in 21 files pass. A fresh `install-ported` run uses
the registered patch, rebuilds, tests and installs without an AI agent.

The validated profile is installed XPerl v5.45.5, commit
`8903238ce74fc124ec407b8342791ef73253f988`, x86_64 Linux, GCC 13.3.0,
`PERL_RC_STACK`, no threads, no multiplicity, no debugging, double NV,
without longdouble or quadmath. Other profiles and ordinary Perl are
untested. The patch combines a general XS bug fix with an XPerl exception
adaptation, so it is not an RC-only patch.

The reusable guidance is linked from [index.json](index.json). The automated
[evidence](evidence/repair-v5.45.5-0.21-98a961adafbc.json) preserves upstream
issue and pull-request references checked during repair.
