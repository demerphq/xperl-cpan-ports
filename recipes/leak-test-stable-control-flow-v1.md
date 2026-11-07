# Keep leak-test control flow stable

Some leak helpers execute a code block more than once. Test::LeakTrace
`no_leaks_ok` first runs the block to warm caches, then measures another run.
If random input selects different branches, the measured change in live
scalars can reflect different retained state rather than a leak. This is
especially visible when one run throws an exception and the other does not.

Make the intended branch deterministic in the measured block. For an
exception-path test, choose input known to throw on every invocation. Keep a
separate non-throwing test if both paths matter. Do not relax the leak limit
or disable the leak check merely to make an intermittent result pass.

List-MoreUtils-XS 0.430 provides an example. Its `binsert` test searched a
list of even numbers but chose an item randomly from 1 through 100. The
comparison callback threw only when the item was already in the list. With
XPerl v5.45.5 and Test::LeakTrace 0.17, repeated original runs reported
-46, 0, or +47 leaked scalars. Setting the item to 100 makes the callback
throw during both warm-up and measured runs. The focused test passed 20
consecutive runs with zero reported leaks. All 61 distribution test files
and 4,519 tests passed under XPerl v5.45.5 and Perl v5.36.3.

### Why XPerl shows the difference

Two kinds of state are left behind when the block dies, and neither is a
leak:

- `$@` holds an `XPerl::Exception` object, about 47 scalars, not a string.
  It outlives the block and is freed only when `$@` changes. On ordinary
  Perl, `$@` reuses one string scalar.
- The first exception in a process blesses its diagnostics into
  `XPerl::Diagnostic::*` classes, so `PL_stashcache` gains one entry per
  class, about five scalars. Later exceptions add nothing.

If the warm-up run does not throw and the measured run does, both appear as
leaks. If only the warm-up throws, clearing `$@` shows up as a negative count.
With input that throws on every run, the warm-up sets up both kinds of state,
and the measured run leaves the count unchanged. Memory stays flat across
300,000 exceptions.

List-MoreUtils 0.430 (the pure-Perl distribution) has the same pattern in
six leak tests: binsert, bsearch, bsearchidx, equal_range, lower_bound and
upper_bound, each in its `t/inline`, `t/pureperl` and `t/xs` copies.
lower_bound and upper_bound chose from 0..999 against a list of 1..100, so
their exception path ran only about one time in ten. Each now uses an item
that is in its list, and all six are confirmed to throw under both the
pure-Perl and XS implementations. The affected tests passed 560 runs without
a failure, and the full suite (122 files, 9,066 tests) passes on XPerl
v5.45.5 and Perl v5.44.0.

List-MoreUtils-XS 0.430 now uses the same fixed items in all six tests, in
its `t/inline` and `t/xs` copies. Each case throws on every call. On the
original archive, 15 of 40 runs of the six tests failed with 47 leaked
scalars (binsert, lower_bound and upper_bound). With the patch, 40 of 40
runs pass, and the full suite (61 files, 4,519 tests) passes on XPerl
v5.45.5 and Perl v5.44.0.
