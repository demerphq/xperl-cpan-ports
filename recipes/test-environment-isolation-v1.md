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

A test helper with `#!/usr/bin/env perl` must also resolve the same Perl that
is running the test suite. If the test sanitizes `PATH`, set it to the
directory containing `$^X` before invoking that helper. The `ack` 3.10.0
patch covers both this pager case and tests that expect colored output.

## Taint-mode subprocesses

A child Perl invoked with `-T` ignores `PERL5LIB`. Pass trusted source
library directories with explicit `-I` arguments. Dpkg 1.23.9's taint
checks need `-Ilib` to find their own modules in a CPAN build. Do not
disable taint mode or install the distribution before running its tests.
Its repaired suite passes 13,252 checks on installed RC XPerl v5.45.5.

## Generated test trees and reconfiguration

Tests can deliberately create cyclic or dangling symlinks. A later build
configuration must account for those generated files if it scans the
source tree. Dpkg's `t.tmp` directory is a test artifact, but
ExtUtils::Manifest follows its cyclic symlink during reconfiguration.
Its Build.PL clears that specific generated tree before the manifest scan.
Keep cleanup scoped to known generated directories, and verify that it
does not follow symlinks outside the tree. Do not include the generated
files in the compatibility patch.

## External service data

Tests of returned data should create the data they expect. A public
website's cookie policy is not part of libcurl's cookie-list API. Seed a
temporary Netscape cookie file, close it before the library opens it, and
compare the exact entry returned by the API. Use a reserved fixture domain
so the test cookie is not sent to unrelated public services. Preserve
feature checks for older native-library versions.

WWW-Curl 4.17 uses this pattern in its HTTP test and its added local-file
regression tests. A clean registry-only install passes 856 tests in 23
files on installed RC-stack XPerl v5.45.5 with libcurl 8.5.0. The original
network transfers remain in the full suite. Distinguish a failed network
connection from a library assertion failure, and do not count a restricted
or focused local run as a full-suite pass.
