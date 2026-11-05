# Rethrown exception text in XPerl

XPerl records propagation context when an exception is caught and explicitly
rethrown with `die $@`. Its rendered text keeps the original diagnostic and
adds a line like `...propagated at file line N.`. A CPAN test that compares the
entire rendered `$@` string with the original message can therefore fail even
when the module's behavior is correct.

Inspect the rethrow path before changing a test. On XPerl, query the
exception graph by diagnostic code and named parameters. For a plain text
error, `ERROR_USER_TEXT` has a `text` parameter holding the original message.
For example:

```perl
my $error = $@;
require XPerl::DiagGroup;
ok($error->has_diagnostic('ERROR_USER_TEXT', text => "bad exit\n"),
   'original error survives rethrow');
```

Keep the ordinary Perl assertion in the other branch. Check a propagation
diagnostic by its code when the test needs to verify the rethrow itself. If
the object API is not available at that boundary, match the complete original
message and allow only the specific propagation line. Keep that pattern
anchored. Do not remove propagation context or change the module's exception
handling merely to satisfy an exact-string test.

The `Capture-Tiny` 0.50 patch is an example. Its adjusted test passes under
XPerl v5.45.5 and ordinary Perl v5.38.2. This recipe does not assert that
every `$@` difference is propagation context; inspect each failure first.
