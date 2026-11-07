# Direct hash-entry traversal in XPerl

XPerl's experimental hash storage uses compact entries rather than linked
bucket chains. HeNEXT and HeSHARED_NEXT are removed. XS code that calls
HeNEXT may compile with an unresolved symbol and then fail when its shared
library loads.

For direct traversal that must leave the public hash iterator untouched, use
HvENTRY_LIMIT(hv) to bound the storage scan. At each position, obtain the
first live entry with HvENTRY_FIRST(hv, i) and advance with
HvENTRY_NEXT(hv, entry). Do not treat HvARRAY as an array of bucket-head
pointers. Use the ordinary hv_iterinit and hv_iternext APIs when changing
the iterator is acceptable.

An HE pointer can move when an entry array grows or compacts. Reacquire
entries after callbacks that may insert, delete, or reserve hash keys.
When retaining a borrowed entry across a callback, keep a stable key and
verify or refetch the entry before use. Test iteration state, callbacks,
mutation detection, and sorted and unsorted hash encoding.

Keep the existing ordinary Perl traversal under an XPERL_VERSION preprocessor
guard when it depends on linked bucket chains. The Sereal-Encoder 6.003 and
7.001 patches are tested examples for XPerl v5.45.5.

Stats-LikeR 0.3416 exercises a further iterator boundary. It preserves a
caller's `each` position while scanning hash storage directly. If a callback
deletes the current key, XPerl frees that entry when the iterator resets.
Restore the saved storage index without restoring the freed `HE` pointer.
Test deletion during a callback and continuation of the caller's `each`
loop. Its patched suite passes 254 files and 69,702 tests on XPerl v5.45.5;
the ordinary Perl branch compiles on v5.44.0.

Code that measures memory, rather than only visiting entries, must also size
the storage itself. Entries live in one array: a linear hash
(`HvIS_LINEAR`) allocates `HvLINEAR_CAP(hv)` of them, and an open-addressed
hash adds a `struct hv_oa` header, an index area, and `HvOA(hv)->capacity`
entries. The entries are counted with the array, not one allocation each.
Shared keys are `struct shared_hek` (a reference count before the key), not
`struct shared_he`. Core's index-area size macros are not available to XS,
so a port that needs the exact figure mirrors them for each storage option.
The Devel-Size 0.87 patch is an example; it passes its suite on XPerl
v5.45.5 and Perl v5.44.0.
