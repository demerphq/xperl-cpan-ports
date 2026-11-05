# Unicode escape spelling in Data::Dumper tests

Some XPerl builds render named Unicode characters in Data::Dumper output as
\N{NAME} where ordinary Perl renders the same character as \x{HEX}. A
test that compares an entire formatted diff or dump against one spelling can
fail even when the data and diff are correct.

Check the actual Data::Dumper mode used by the distribution. When a test
needs to verify exact formatting, derive the expected spelling from that
mode and keep the rest of the expected output exact. Avoid replacing the
assertion with a broad substring check. Do not rewrite the underlying data
to make one rendering style win.

The Test-Differences 0.73 patch detects Data::Dumper's escape style and
selects one of two complete expected tables. Its test passes under XPerl
v5.45.5 and ordinary Perl v5.38.2.
