# Reference-counted stacks and coroutine switches

Custom operations that switch interpreter stacks need an ownership audit
across the switch. Look for saved `PL_curstackinfo`, `PL_stack_base` and
stack-pointer offsets, private `new_stackinfo` calls, and operations that
bypass `pp_entersub` after their first call. Coro 6.57 is an example.

The `XSPP_wrapped` bridge described in `refcounted-stack-custom-op-v1`
assumes its argument and result frames belong to the expected stack. Do not
apply it blindly to an operation that switches stacks while it runs. Such
code may need explicit ownership in its custom operations and callbacks.

Audit these boundaries together:

- Newly created coroutine stacks need the owning-stack state expected by
  the interpreter. An ordinary XSUB can still use a non-RC compatibility
  frame on an RC-enabled interpreter. Check the actual stack kind before
  changing reference counts.
- A first call through the XSUB wrapper can use a duplicated argument
  frame. Offsets retained after that XSUB returns must identify the frame
  that survives wrapper cleanup.
- Arguments needed by a later prepare or resume callback must remain alive
  after removing their stack slots. Transfer or retain ownership explicitly.
- Scalar, list and void results must release discarded owned stack values.
  Use the interpreter's context/stack APIs where their contract fits.
- Private records containing raw pointers or integers are not SV references.
  Keep their lifetime separate from RC cleanup. Existing raw records stored
  temporarily on a value stack must be removed before Perl uses or destroys
  that stack. Do not increment or decrement them as if they were SVs.

Test direct and indirect calls, adjacent list values, repeated callbacks,
returned-reference lifetimes, cancellation of suspended coroutines, pool
reuse and tracing. Weak references and destructor counts can expose leaks
that produce no warnings. Check warning-free execution as well. A passing
normal XSUB call does not establish that a custom scheduling operation works.

The Coro repair is guarded by `PERL_RC_STACK`, without requiring XPerl.
Fresh builds pass 21 files and 223 tests on ordinary Perl v5.44.0,
ordinary Perl v5.45.4 with DEBUGGING and PERL_RC_STACK, and XPerl v5.45.5
with PERL_RC_STACK. The recorded XPerl configuration is x86_64 Linux,
GCC 13.3.0, no ithreads or DEBUGGING, and NV double. These results do not
establish threaded, longdouble or quadmath compatibility, nor validate
Coro's experimental cloning or optional event-loop integrations.
