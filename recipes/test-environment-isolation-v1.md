# Isolate environment-dependent assertions in CPAN tests

A test that expects exact terminal output needs to establish the environment
that produces that output. `NO_COLOR` suppresses ANSI escapes in
`Term::ANSIColor`, so comparing its output with hard-coded escape sequences
fails when `NO_COLOR=1` is inherited from the caller.

Localize the relevant environment variable around the affected assertions.
Keep the scope narrow and leave the module's normal behavior intact. The
`YAML-PP` v0.43.0 patch clears `NO_COLOR` for its color assertions. Its full
suite passes with `NO_COLOR=1` under XPerl v5.45.5 and Perl v5.36.3.
