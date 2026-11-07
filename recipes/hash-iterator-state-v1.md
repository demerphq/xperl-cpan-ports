# Hash iterator state across callbacks in XPerl

Look for XS code that saves a hash iterator position, visits entries,
calls Perl code, and restores the iterator. A callback may delete an entry
and free its `HE` when the iterator resets. Preserve a stable storage index
or key and refetch the entry after the callback; do not restore a freed
pointer. Test deletion and insertion during callbacks and continuation of
the caller's `each` loop.

Stats-LikeR 0.3416 exercises this boundary. Its patched suite passes 254
files and 69,702 tests on XPerl v5.45.5; the ordinary Perl branch compiles
on v5.44.0.
