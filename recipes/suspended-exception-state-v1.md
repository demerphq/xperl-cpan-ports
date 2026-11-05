# Preserve XPerl exception state across suspended execution

XPerl keeps the current structured exception in ${^ERROR_OBJ}, backed by
PL_errorobjgv. Async implementations that detach and restore Perl savestack
entries must preserve this localized scalar alongside $@. A guard that only
accepts PL_errgv rejects XPerl's SAVEt_SV entry and can abort when an async
frame suspends.

For XPerl, permit PL_errorobjgv through the same SAVEt_SV suspend and resume
path used for PL_errgv. Keep the existing guard on ordinary Perl. Test nested
awaits, local $@, and exceptions crossing async frames. XPerl may append a
propagation frame to the rendered text, so assertions should recognize the
exception text and frame rather than require the old byte-for-byte string.

Future-AsyncAwait 0.71 demonstrates this on XPerl v5.45.5. Its 52 test files
and 226 tests pass after the conditional port.
