# Isolate environment-dependent assertions in CPAN tests

A test that expects exact terminal output must establish the environment
that produces it. `Term::ANSIColor` suppresses ANSI escapes when `NO_COLOR`
is defined or `ANSI_COLORS_DISABLED` is true. A test that expects escape
sequences must clear those variables for its own assertions, even if it
sets a library-specific color flag. The test must not depend on the caller
leaving them unset.

Localize the relevant variables in the smallest block that tests colored
output. For example:

```perl
subtest 'Colorized output' => sub {
    local $ENV{NO_COLOR};
    local $ENV{ANSI_COLORS_DISABLED};
    # Assertions that require ANSI escapes.
};
```

Keep the module's normal behavior intact. Do not make the installer discard
the caller's environment to get such a test passing. Run the affected test
with `NO_COLOR=1` and `ANSI_COLORS_DISABLED=1`, then run it under ordinary
Perl as well as XPerl. The `YAML-PP` v0.43.0 patch clears `NO_COLOR` for its
color assertions; its full suite passed with `NO_COLOR=1` under XPerl
v5.45.5 and Perl v5.36.3. The `Mojolicious` 9.53 patch clears both variables
for its color subtest; that test passes under XPerl v5.45.5 and Perl v5.38.2.

The installer sets `NONINTERACTIVE_TESTING=1` during tests and
`PERL_MM_USE_DEFAULT=1` for configure, build, and test, following CPAN
client practice. These flags prevent prompts; they do not request ANSI
color or cancel `NO_COLOR`. `AUTOMATED_TESTING` denotes a smoke tester and
must not be set by an ordinary CPAN install. When a test assumes colored
output, fix the test's local environment as above.
