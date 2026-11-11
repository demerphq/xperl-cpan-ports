# Replace private bucket-chain lookup with the public hash API

XPerl hashes do not use Perl's linked bucket chains. A helper that indexes
`HvARRAY(hv)` with a precomputed hash and walks `HeNEXT` must not keep that
algorithm on XPerl. This is a key lookup, rather than an iteration task.

When the caller needs an `HE *`, construct the key with its explicit byte
length and use `hv_fetch_ent(hv, key_sv, 0, hash)`. Release the temporary key
after the lookup. Preserve the key's UTF-8 flag when the caller's contract
requires it. A zero hash argument lets the interpreter compute the hash.
Keep an existing precomputed hash only when it uses the interpreter's hash
algorithm and seed for those exact key bytes and flags.

Do not replace lookup with a full entry scan. Preserve the existing ordinary
Perl path under `#ifdef XPERL_VERSION` when its implementation or performance
requirements depend on the traditional hash layout. The public API is also
available on ordinary Perl, so a later general cleanup can be considered
separately from the compatibility patch.

The returned entry is borrowed. It can move when the hash grows or compacts.
Do not keep an `HE *` or `SV **` across mutations or callbacks. Retain the
value when needed and reacquire the entry by key afterward. See
`hash-value-lifetime-v1` for that ownership boundary.

mod_perl 2.0.13 uses this repair in `modperl_perl_hv_fetch_he`. Its package END-list
regression exercises the lookup while the internal table grows through
several sizes. For a focused lookup probe, include missing keys, deleted
entries, undefined values, embedded NULs, shared prefixes and precomputed
hashes. Repeat after interpreter cloning when threads are supported.
