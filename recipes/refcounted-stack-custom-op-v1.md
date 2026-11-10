# Reference-counted stacks and custom operations

An XS distribution can pass its ordinary function tests while its custom
operations leak arguments, release live scalars, or disturb adjacent values
on a reference-counted stack. Custom operations bypass the normal entersub
path that adapts a traditional XSUB to stack ownership. Inspect custom
`op_ppaddr` functions, call checkers, direct XSUB calls, `TOPs` and `SETs`.

When the custom operation has a known argument count and uses traditional
stack conventions, the interpreter's `XSPP_wrapped` bridge can preserve that
implementation while adapting argument and result ownership. Guard the
bridge for interpreters that provide it and for `PERL_RC_STACK`. Counts must
include optional arguments selected by the operation's flags, not just its
minimum arity. Sereal-Decoder 7.001 demonstrates flag-dependent counts and
one-argument inspection operations.

Select RC ownership code with `#ifdef PERL_RC_STACK`. Do not require
`XPERL_VERSION`: ordinary Perl can use the same refcounted stack. The RC
build provides `XSPP_wrapped`; conventional-stack builds retain their
original declarations. Keep unrelated XPerl hash or exception changes under
their own feature guards. Validate the patch on ordinary RC Perl as well as
RC XPerl before claiming support for both interpreters.

Some optimizations call an XSUB directly from a replacement entersub and
cannot use that bridge unchanged. Class-XSAccessor 1.19 demonstrates keeping
normal XSUB dispatch on RC builds so the interpreter's compatibility wrapper
owns the transition. Its ordinary-stack optimization remains available.
This is a provider repair. When a consumer disables an optional accelerator
because of this failure, investigate and fix the accelerator itself before
accepting the consumer workaround as the final solution.

Ref-Util-XS 0.117 is another one-argument bridge example. Its predicates
replace their input with a boolean using `SETs`. The ordinary XSUB path
balances ownership, but the custom operation bypasses that wrapper and
leaks its input on an RC stack. Wrapping the custom operation fixes the
provider while keeping its optimization enabled. The failure first appeared
as a Type-Tiny coercion retaining its input hash. Rebuilding unmodified
Type-Tiny against the repaired provider passes its suite with acceleration
enabled. Check both the provider's argument lifetime and the consumer's
original reproducer before accepting a workaround that disables acceleration.

Do not mix a local `SP` snapshot with `rpp_*` updates without publishing and
refreshing the appropriate pointer. Callback instrumentation can run on
either stack kind; see `refcounted-stack-callback-v1` for that case.

Check compile-time hooks separately from wrapped runtime operations.
Data-Alias 1.30 saves an immortal boolean on the value stack in its `rv2cv`
check hook and restores it in its `entersub` check hook. The compiler can
call these hooks with an RC stack even though the runtime handlers use
`XSPP_wrapped`. Select the push and pop APIs using `rpp_stack_is_rc()` on RC
builds, retaining the original operations when a compatibility stack is
active. A non-debug build can miss legacy stack macros used in this way.
Run the full parser-heavy suite with an installed debug RC interpreter so
the stack assertions expose those paths.

Test scalar, list and void contexts, optional output arguments, and adjacent
stack values. Use weak references or destruction counts to prove consumed
arguments are released, and test ordinary XSUB calls as a control. Keep
warning checks in addition to lifetime checks: a leak need not warn. Verify
the custom operation is actually exercised rather than silently disabled.
Run the complete distribution suite and retain the exact build profile and
patch digest. An RC result does not establish an ordinary-stack, threaded,
debugging, longdouble or quadmath result.
