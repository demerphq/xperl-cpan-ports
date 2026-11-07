# Direct hash metadata changes in XPerl

Look for XS assignments through `HvMAX` or direct swaps of hash metadata.
XPerl's public `HvMAX` view need not be an lvalue. Code that truly must
modify the stored field can use `HvMAX_RAW` under `#ifdef XPERL_VERSION`.

Changing one field is not enough if the code moves hash storage between
objects. Review the storage representation, key counts, iterator state,
and ownership together. Test empty and populated hashes, then add and
delete keys after the swap. Hash-Spy 0.01 is a candidate example; its
behavior should be checked on more than one storage size.
