# Rethrown exception text in XPerl

XPerl records propagation context when an exception is caught and explicitly
rethrown with `die $@`. Its rendered text keeps the original diagnostic and
adds a line like `...propagated at file line N.`. A CPAN test that compares the
entire rendered `$@` string with the original message can therefore fail even
when the module's behavior is correct.

Inspect the rethrow path before changing a test. If the test intends to check
that the original message survives, match the complete original message and
allow the specific propagation line. Keep the pattern anchored so unrelated
text cannot pass. Do not remove the propagation context from XPerl or change
the module's exception handling merely to satisfy an exact-string test.

The `Capture-Tiny` 0.50 patch is an example. Its adjusted test passes under
XPerl v5.45.5 and ordinary Perl v5.38.2. This recipe does not assert that
every `$@` difference is propagation context; inspect each failure first.
