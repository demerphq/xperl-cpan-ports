# Reference counts with a reference-counted stack

Tests or diagnostic tools that inspect `REFCNT`, `SvREFCNT`, `B::svref_2object`,
or `Devel::Peek` may observe additional references while arguments are on a
reference-counted stack. XPerl v5.45.5 supports this configuration with
`-Accflags=-DPERL_RC_STACK`; ordinary Perl builds can enable it too.

Check what the tool promises to report. A raw diagnostic should report the
actual count. A tool that excludes its own temporary references may need to
account for references held by its particular call path. Do not subtract a
fixed amount from all counts: the number of live stack references depends on
the call path. Where available, `Internals::stack_refcounted() & 1` identifies
an interpreter built with the option; retain a compatible path for older Perl.

For tests that only check the shape of a dump, normalize a positive count
instead of expecting a fixed value. Keep assertions about actual ownership or
lifetime when those are the behavior under test. Data-Peek 0.54 illustrates
the former; Data-Printer 1.002001 adjusts its own circular-reference reporting.
Rebuild from the original archive with the consolidated patch and test both
the reference-counted and ordinary stack configurations. Test ordinary Perl
when the fix is intended to be portable there.
