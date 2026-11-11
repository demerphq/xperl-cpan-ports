# Release native payloads before Perl's final SV sweep

## Symptom and cause

An XS extension crashes during global destruction even though its tests
finish normally. A native payload holds Perl values such as an `HV *` cache
and an `SV *` return buffer, and CV free-magic releases that payload.

Perl's final `sv_clean_all` sweep decrements every remaining SV. It can free
the cache, its values or the return buffer before freeing the CV. The
native pointers then dangle. An extra reference count does not establish a
safe shutdown order. Testing the dangling value's type or skipping its
destructor hides the lifetime defect.

Affix v1.4.0 demonstrates this with callable struct members left alive at
exit. Under ordinary Perl v5.45.4 with `PERL_RC_STACK`, `DEBUGGING`,
`DEBUG_LEAKING_SCALARS` and `PERL_DESTRUCT_LEVEL=2`, a fixed hash seed makes
`t/999_marshaller_2.t` abort in `hv_iterinit` after its TAP plan. Both the
cache and the reusable return scalar have already been freed.

## Preferred repair

Track live native payloads without retaining their Perl owners. Unlink a
payload during normal free-magic cleanup. Register one `call_atexit` hook
per interpreter to release surviving payloads after Perl object destructors
and before the final SV sweep. Clear the CV magic's payload pointer before
freeing it, so later CV cleanup cannot release it twice.

Keep the list private to its interpreter. Initialize it at startup and reset
it when cloning interpreter-local state. Preserve ownership checks so a
child interpreter cannot unlink or free a parent's payload. Avoid adding
work to the extension's call path when linking and unlinking at construction
and destruction are sufficient.

This is a general Perl lifetime fix. It needs no `XPERL_VERSION` or
`PERL_RC_STACK` condition. Preserve any separate RC-stack repairs.

## Validation

Use a child process to test complete shutdown, including its exit status
and signals. A TAP plan alone cannot detect an abort that happens afterward.
Run with `PERL_DESTRUCT_LEVEL=2` and several fixed hash seeds, then run the
complete distribution suite. Exercise normal destruction too, so the exit
hook does not revisit freed list entries.

Record each interpreter's exact configuration and patch digest. A debug RC
pass does not establish coverage for conventional stacks, threads,
longdouble, quadmath or other operating systems.
