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

Keep the existing ordinary Perl traversal under an XPERL preprocessor
guard when it depends on linked bucket chains. The Sereal-Encoder 6.003
patch is a tested example for XPerl v5.45.5.
