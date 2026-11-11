# Keep hash values alive across calls into Perl

An XS lookup such as `hv_fetch` returns an `SV**` into hash storage. Calling
Perl code, including overload methods or tied-hash hooks, may change that
hash. A saved entry pointer can then be invalid even when the value itself
still exists. XPerl's hash layout exposed this in `HTML::Parser` 3.86 when
stringifying one entity value deleted another key from the same hash.

Copy the `SV*` out of the entry before the call. Increase its reference count
and arrange cleanup after the last use. Read flags and string data through
the retained `SV*`, not through the old `SV**`. If a returned character
pointer refers into that value, keep the value alive until the copy is done.
This change is also safe on ordinary Perl and does not need an
`XPERL_VERSION` guard.
`Text::CSV_XS` 1.65 had the same pattern without any callback: it stored
into the object hash (`hold_sv`) and then read through the `SV**` from an
earlier `hv_fetch`, which crashed in `cx_SetupCsv` once XPerl moved the entry.

Chandra 0.31 exposes the same lifetime boundary in several header and XS
fragments. Listener setup inserts object keys before using a cached slot.
Route callbacks can grow the application hash while XS retains pointers to
its fields. Fetch the slot after the last possible mutation, or retain an
owned value before calling Perl. A callback can replace or delete the entry,
so merely copying the `SV*` without retaining it is insufficient.

Its regression suite grows the object hash during a route callback and
checks listener setup without opening a display or socket. The registered
repair passes with installed Linux RC XPerl v5.45.5, without threads or
debugging. Other profiles need their own validation.

Test hash mutation during overload or tied hooks, especially deletion,
rehashing, and changes to the input string. The `HTML-Parser` 3.86 patch
passes its full suite under XPerl v5.45.5 and Perl v5.36.3.
