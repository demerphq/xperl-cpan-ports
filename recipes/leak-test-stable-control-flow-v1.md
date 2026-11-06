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
