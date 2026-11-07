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
require XPerl::DiagGroup unless $error->can('has_diagnostic');
ok($error->has_diagnostic('ERROR_USER_TEXT', text => "bad exit\n"),
   'original error survives rethrow');
```

Keep the ordinary Perl assertion in the other branch. Check a propagation
diagnostic by its code when the test needs to verify the rethrow itself. If
the method is built into XPerl, the compatibility line above loads nothing;
older builds with the same XPerl version need the Perl module. If
the object API is not available at that boundary, match the complete original
message and allow only the specific propagation line. Keep that pattern
anchored. Do not remove propagation context or change the module's exception
handling merely to satisfy an exact-string test.

The `Capture-Tiny` 0.50 patch is an example. Exception::Died 0.06 uses the
original `ERROR_USER_TEXT` parameter to populate its `eval_error` field.
Both patches pass on XPerl v5.45.5 and ordinary Perl. This recipe does not assert that
every `$@` difference is propagation context; inspect each failure first.

## Library messages built from a rethrown exception

The propagation line can also reach a library's own output. If a library
catches an error, rethrows it with `die $@`, and later stringifies the value
into a message for its callers or clients, that message gains
`...propagated at FILE line N.`, including a server-side path. On ordinary
Perl, a message ending in a newline carries no location.

Fix this at the point where the library turns the error into text, not at
the rethrow. Leave ordinary Perl strings and other objects unchanged. For an
`XPerl::Exception`, ignore `ERROR_PROPAGATION_RETHROW_CONTEXT` roots. If one
`ERROR_USER_TEXT` root remains, use its `text` parameter when it ends in a
newline; otherwise use that diagnostic's `render` plus a newline, which
matches the ordinary Perl `die "text"` string. Keep the full rendering for
anything else, because rendering composite diagnostics one root at a time
does not match the legacy text. Keep the object itself where the library
stores an original error.

`GraphQL` 0.54 is a worked example. `GraphQL::Error->coerce` builds the
client-visible `message` this way, and its test helper accepts trailing
propagation lines after the complete expected message. Its 24 test files and
387 tests pass on XPerl v5.45.5 and Perl v5.44.0.
