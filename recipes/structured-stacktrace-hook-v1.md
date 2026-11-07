# Capture XPerl stack traces from canonical exceptions

Legacy stack-trace middleware often uses `$SIG{__DIE__}` and keys traces by
the text passed to the hook. XPerl's `${^XPERL_VERSION}` flag identifies the
runtime, and `$SIG{__EXCEPT__}` receives the canonical `XPerl::Exception`
before the legacy hook. Explicit rethrows retain the same exception object
and append propagation diagnostics. Keying a trace by `refaddr` of that
object keeps the first stack trace across rethrows and distinguishes a
nested exception raised by a destructor.

For XPerl, design trace handling around the canonical exception received by
`__EXCEPT__`. Do not route it through an existing `__DIE__` formatter or
render and rethrow its text: that loses diagnostic codes, parameters, and
object identity. Retain the ordinary `__DIE__` path for Perl and
user-thrown references. `Try::Tiny` may clear
`${^ERROR_OBJ}` before its catch callback, while `$@` still exposes the
canonical object for text exceptions. Test both text and reference throws.

A handler that builds a stack trace must avoid expected internal exceptions.
For example, `Devel::StackTrace` probes a scalar `ignore_package` with an
`eval`; passing an array reference avoids that probe inside `__EXCEPT__`.
Check fatal severity before recording a trace, because the hook also sees
warnings. The Plack 1.0057 patch demonstrates these choices and passes its
full suite on XPerl v5.45.5.

This case also defines useful behavior for XPerl's future built-in stack
traces: retain the first capture for a canonical exception, preserve it
through explicit propagation, and keep nested exceptions separate. Review
legacy `__DIE__` handlers for migration to `__EXCEPT__` during AI-assisted
ports, but inspect their handling of reference throws and warnings first.

A native port is complete only when a focused probe shows that the original
diagnostic code and parameters survive, the exception retains its identity
through rethrows, and trace handling keeps nested exceptions separate. Test
warning-only exceptions and expected internal exceptions when the hook can
see them. A passing distribution suite alone does not establish this. If a
stable core API is needed to attach a trace, keep the port marked
`needs-core-api` until that API and its focused tests exist.

## Handler survey

Passing distribution tests does not establish that a handler preserves the
diagnostic graph. Devel::Confess 0.009004 passes its suite on XPerl v5.45.5,
but its `__DIE__` handler renders and rethrows a native division-by-zero
error. The caught exception then has `ERROR_USER_TEXT` instead of
`ERROR_NUMERIC_DOMAIN_DIVISION_BY_ZERO`. Its stack trace appears in the
rendered text. Passing the canonical exception to Devel::Confess's existing
`_convert` helper is unsafe: that helper reblesses the object, and the
experiment segfaulted on XPerl. A port needs to preserve the canonical
object and attach trace information without reblessing it or rethrowing its
rendered text. The current public diagnostic API does not provide a stable
way to add a stack trace, so this case needs a core API decision before a
distribution patch.

Carp::Always 0.16 has the same diagnostic-loss pattern. Its `__DIE__`
handler calls `die` with a `Carp::longmess` string. A native division-by-zero
error becomes `ERROR_USER_TEXT` after the handler runs. Its distribution
tests pass, so a focused diagnostic-code check is needed when evaluating
trace middleware.

MCE 1.904 passes its suite on XPerl, but its `__DIE__` handler examines
`$^S`, writes an error and may exit a worker. Treat it as worker-control
code, not just trace formatting. An MCE::Child probe with a dying child
reports the error to its parent. Test::FailWarnings 0.008 and
Test::NoWarnings 1.06 pass their suites and focused warning-capture probes;
their `__WARN__` handlers consume rendered text, which XPerl continues to
supply. These uses do not call for a mechanical switch to `__EXCEPT__`.
