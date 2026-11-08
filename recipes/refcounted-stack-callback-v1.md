# Stack ownership in native callbacks

Native instrumentation that calls Perl from an opcode hook can run on a
reference-counted stack, even when an ordinary XSUB uses a compatibility
stack. Inspect callbacks using `call_sv`, `call_pv`, or `call_method` together
with `PUSHMARK`, `XPUSHs`, `POPs`, or direct `SP` manipulation. These patterns
identify code to inspect, not proof that every such call is broken.

On a reference-counted stack, each occupied slot owns a reference. A callback
that pushes a mortal argument needs an additional reference for that slot.
A callback that removes a returned scalar must release the slot's reference
after consuming the value. Publish the updated stack pointer with `PUTBACK`
before an operation that can run Perl, including conversion or destruction.

Check the actual stack kind at the callback site. Where available, guard
the additional ownership changes with `#ifdef PERL_RC_STACK` and
`rpp_stack_is_rc()`. Compiling with the option does not imply that every
callback uses an RC stack. Keep the original ownership behavior for a
compatibility stack and for interpreters without the option. Prefer the
interpreter's stack APIs when their ownership contract fits the call path.

Devel-Cover 1.52 demonstrates this in its `Devel::Cover::use_file` callback:
the pushed filename gains an RC-stack reference, and the popped boolean
result loses its reference after its value is read. The consolidated patch
retains the previous XPerl coverage expectations. Its recorded validation is
on XPerl v5.45.5 with PERL_RC_STACK, without threads or debugging. This does
not establish validation on other configurations.

Test repeated callbacks and check object lifetime or reference balance.
Run the distribution's complete suite on both stack configurations and
ordinary Perl where the port is intended to work there. Do not normalize
away a leaked reference. A raw diagnostic tool displaying a legitimately
different count is a separate case, covered by
`refcounted-stack-observation-v1`.
