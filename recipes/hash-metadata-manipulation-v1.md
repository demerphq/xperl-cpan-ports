# Direct hash metadata changes in XPerl

Look for XS assignments through `HvMAX` or direct swaps of hash metadata.
XPerl's public `HvMAX` view need not be an lvalue. Code that truly must
modify the stored field can use `HvMAX_RAW` under `#ifdef XPERL_VERSION`.

First determine why the code assigns that field. If it only reserves space
for entries, prefer `hv_ksplit(hv, expected_keys)` over direct metadata
updates. mod_perl 2.0.13's environment-copy helper uses the source hash's
key count to reserve destination storage on XPerl. That expresses its
capacity requirement without assuming a bucket count or representation.

Changing one field is not enough if the code moves hash storage between
objects. Review the storage representation, key counts, iterator state,
and ownership together. Test empty and populated hashes, then add and
delete keys after the swap. Hash-Spy 0.01 is a candidate example; its
behavior should be checked on more than one storage size.
