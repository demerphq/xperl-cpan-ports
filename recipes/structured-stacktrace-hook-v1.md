# Capture XPerl stack traces from canonical exceptions

Legacy stack-trace middleware often uses `$SIG{__DIE__}` and keys traces by
the text passed to the hook. XPerl's `${^XPERL_VERSION}` flag identifies the
runtime, and `$SIG{__EXCEPT__}` receives the canonical `XPerl::Exception`
before the legacy hook. Explicit rethrows retain the same exception object
and append propagation diagnostics. Keying a trace by `refaddr` of that
object keeps the first stack trace across rethrows and distinguishes a
nested exception raised by a destructor.

Use `__EXCEPT__` for XPerl's text exceptions, and retain the ordinary
`__DIE__` path for Perl and user-thrown references. `Try::Tiny` may clear
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
