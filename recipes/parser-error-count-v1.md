# Use XPerl's diagnostic error count in parser XS

Ordinary Perl stores compile error count in the parser structure. XPerl
tracks it in the pending structured exception instead, so XS code that reads
or increments the parser field no longer compiles. XPerl exposes
PERL_DIAG_ERROR_COUNT in perl.h for checking the current count.

Keep the ordinary Perl parser field path under the non-XPerl branch. Under
XPERL_VERSION, read PERL_DIAG_ERROR_COUNT. Do not increment the old parser
field before croak_sv in XPerl: fatal diagnostic delivery updates the pending
exception. Check every read and write of the old field in the distribution,
including keyword and infix plugin callbacks.

XS-Parse-Keyword 0.51 is a worked example. After the conditional port, its
25 test files and 195 tests pass on XPerl v5.45.5. XS-Parse-Sublike 0.42
needs the same count substitution in both its XS entry point and parser
source. Its private yyerror replacement increments the old field and warns;
under XPerl it instead calls croak_sv so a syntax error terminates parsing.
Its 29 test files and 123 tests pass. Test both successful parses and
syntax-error paths, because the count controls whether a plugin continues
parsing after an error.

## Migrate `PL_errors` separately

`PL_errors` was the old text queue for compiler errors. In XPerl,
`PL_pending_exception` holds the structured exception being assembled during
compilation. `pod/perlexcephack.pod` describes that accumulator, its delivery
boundary, and the separate role of `error_count`. There is no textual
`PL_errors` replacement to concatenate or clear.

First identify what the XS code does with `PL_errors`:

- If it only checks whether parsing has already failed, use
  `PERL_DIAG_ERROR_COUNT` under `XPERL_VERSION`. Keep the ordinary Perl branch.
- If it reads error text to decorate a new failure, preserve the existing
  structured exception and add context without flattening its diagnostics.
  Inspect `ERRSV` and the pending exception separately: an eval failure can
  be in `ERRSV` while earlier compiler diagnostics remain pending. Do not
  stringify and concatenate either object into a new message.
- If it writes to `PL_errors`, determine whether it is producing a recoverable
  compiler diagnostic or delivering a fatal exception. A producer appends a
  diagnostic to the pending exception. A fatal path delivers the complete
  pending aggregate. Do not increment `error_count` by hand, copy the queue
  into `ERRSV`, or clear it as if it were a string.

`Function::Parameters` 2.002006 reads `PL_errors` after `parse_fullexpr`
fails, then joins it to its own `croak_sv` text. Its XPerl branch should retain
the original diagnostic object and attach the inline-constraint context as a
separate diagnostic or exception context. `indirect` 0.39 concatenates a saved
`ERRSV` into `PL_errors`, increments the parser count, clears the queue, and
rethrows. Its XPerl branch should keep the saved exception object, preserve
pending diagnostics in encounter order, and deliver through the structured
exception path. Both migrations need tests that inspect diagnostic identity,
order, and source locations as well as rendered text.

`PL_pending_exception` and the low-level append/flush functions are currently
core internals. Before using them from a CPAN module, check for a supported
XS API in the target XPerl version. If none covers the required operation,
record the missing API and request a core change; do not treat direct writes
to the exception's internal hash as a stable port.

### Worked examples

`croak_sv` is enough for both modules. Under XPerl it appends its argument to
the pending exception and throws the aggregate. An `XPerl::Exception` passed
to it contributes its diagnostics unchanged, and text becomes one more user
diagnostic.

`Function::Parameters` 2.002006 calls `croak_sv` with only its context
message under `XPERL_VERSION`. A syntax error in an inlined check aborts
parsing before this point on XPerl as on ordinary Perl. Errors that do not
abort parsing, such as undeclared variables under `strict`, now come first,
each with its code and source location, followed by the context. Ordinary
Perl puts the context first.

`indirect` 0.39 only saves `ERRSV` under `XPERL_VERSION`, because pending
compiler diagnostics no longer live in `ERRSV`. It restores the saved value
when the hook succeeds, and passes the hook's exception to `croak_sv` when the
hook dies. No core-private API is needed.

If the hook dies with a reference that is not an `XPerl::Exception`, `$@` is
that reference alone, and the earlier compiler errors are not in it. Ordinary
Perl stringifies the reference after them instead.

## Tests that expect an op-check croak to come first

A module that croaks from an op-check hook runs after the core checker. If
the core checker has already queued a compile error, such as "Not enough
arguments for FUNC", XPerl keeps that error first in `$@` and appends the
module's diagnostic. Ordinary Perl replaces the queued errors with the croak
message. A test that anchors the module's message at the start of `$@`
therefore fails on XPerl even though the module still dies correctly.

Keep the module code unchanged. In the test, match the module's message at
the start of a line of `$@`, for example with `/m` on a `^`-anchored pattern.
The test still fails if the module does not die, because the queued core
error alone does not match.

`bareword-filehandles` 0.007 is a worked example. Its `t/basic.t` checks
`FUNC BAREWORD` for each filehandle function. For the 23 functions that
take more than one argument, "Not enough arguments" was queued first, and
24 checks failed. With `/m`, its
2 test files and 483 tests pass on XPerl v5.45.5 and Perl v5.44.0.
