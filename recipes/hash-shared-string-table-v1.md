# Shared string table traversal in XPerl

Look for direct traversal of `PL_strtab`, `HvARRAY`, or shared hash key
storage. XPerl's shared string table uses slots obtained with `HvSTRSLOTS`
and may contain `HvSTR_TOMBSTONE`. Check each slot before reading its
`HEK`, and use `HvSTR_REFCOUNT` for its reference count. A shared key is
stored as `struct shared_hek`, with the reference count before the key.

Keep the ordinary Perl implementation under `#ifdef XPERL_VERSION` when
the layouts differ. Test empty, deleted, and heavily populated tables.
Devel-MAT-Dumper, Devel-SizeMe, and Devel-Arena exercise this pattern.
