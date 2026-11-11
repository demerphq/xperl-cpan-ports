# Affix v1.4.0: resolved shutdown lifetime failure

The selected patch includes the existing `PERL_RC_STACK` callback-member
repair and a general Perl shutdown lifetime fix. It preserves the original
CPAN release and ordinary Perl compatibility.

## Cause and repair

Affix stores a cache hash and reusable return scalar in a native wrapper
payload. CV free-magic releases that payload. A wrapper can survive until
Perl's final `sv_clean_all` sweep, which can free the hash and scalar before
freeing the CV. The native pointers then dangle. The debugger confirmed both
values were freed when `_affix_destroy` tried to iterate the cache.

The repair tracks live payloads in an interpreter-local native list. Normal
CV cleanup unlinks its payload in constant time. A `call_atexit` hook releases
surviving payloads after Perl object destructors and before the final SV
sweep. It clears their magic pointers so later CV cleanup cannot free the
payload twice. The list does not retain CVs and adds no work to wrapped
function calls. Interpreter cloning starts with an empty local list.

This lifetime fix needs no XPerl or RC-stack conditional. The separate
callback-member stack repair remains conditional on `PERL_RC_STACK`.

## Regression and validation

The new `t/092_shutdown.t` runs the existing marshaller regression in child
processes with `PERL_DESTRUCT_LEVEL=2` and hash seeds 0, 1, 15 and 31. It
checks the process exit status, including signals after the TAP plan.
All four checks fail against the earlier patch on ordinary debugging RC
Perl. They pass with the lifetime repair.

Full-suite results and build configurations are recorded in the matching
`evidence/shutdown-*.json` files. Original failed evidence is retained for
the earlier patch digest. It does not describe the selected repair.

| Installed interpreter | Configuration | Full suite |
| --- | --- | --- |
| Perl v5.45.4 | RC, DEBUGGING, DEBUG_LEAKING_SCALARS, no threads | 59 files, 394 tests pass |
| Perl v5.44.0 | Conventional stack, no threads or debugging | 59 files, 394 tests pass |
| XPerl v5.45.5 | RC, no threads or debugging | 59 files, 394 tests pass |
| XPerl v5.45.5 | RC, ithreads, shared libperl, no debugging | 59 files, 386 tests pass |

Both XPerl runs use commit `8903238ce74fc124ec407b8342791ef73253f988`.
The threaded run passes the ithreads and shutdown tests. Its embedding test
`t/018_sv_type.t` skips because its `-lperl` link command cannot find the
shared library. That test has not been validated on this profile. Author
tests are not enabled in these runs.

## Upstream review

Reviewed current main's `lib/Affix.c`, its recent history and open pull
requests before editing. Main retains the same cache/CV cleanup ordering.
[Issue 235](https://github.com/sanko/Affix.pm/issues/235) reports tests passing
followed by an exit failure on Solaris after threaded tests. It provides no
matching native trace, so this investigation does not establish the same
cause. The open Dist::Build conversion does not supply a lifetime fix.
No upstream patch was adapted and no upstream message was posted.

The recurring pattern and verification method are documented in
[`native-payload-shutdown-v1`](../../../../recipes/native-payload-shutdown-v1.md).
Passing profiles do not establish results on other operating systems,
longdouble, quadmath or debugging XPerl.
