# Hash storage size accounting in XPerl

Look for `HvARRAY`, `HvMAX`, `HvLINEAR_CAP`, or `HvOA` in XS code that
reports memory use. An XPerl hash stores entries in a compact array. A
linear hash allocates `HvLINEAR_CAP(hv)` entries; an open-addressed hash has
an `hv_oa` header, an index area, and `HvOA(hv)->capacity` entries.
Count the array allocation once rather than charging each entry for a
separate allocation. Account for index widths and tombstones. Test small
and large hashes, both storage modes, and the ordinary Perl branch.

Devel-Size 0.87 is an example. Shared string table storage needs the
separate `hash-shared-string-table-v1` recipe.
