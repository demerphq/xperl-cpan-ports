# Regex internal API changes in XPerl

Look for direct `regexp` fields, `startp`, `endp`, `nparens`, or calls to an
older `pregcomp` signature. XPerl uses `REGEXP` and accessor macros such as
`RX_NPARENS`, `RX_OFFS_START`, and `RX_OFFS_END`. Build the pattern as an SV
and use the supported compile call for the running XPerl.

Keep an ordinary Perl implementation under `#ifdef XPERL_VERSION` when
its API differs. Test capture offsets, UTF-8 patterns and subjects, empty
captures, and regex object lifetime. perlec 0.08 is an example of a broader
port that includes both regex API and build changes.
