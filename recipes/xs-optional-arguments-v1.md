# Use XS argument defaults without reading absent stack slots

An XS signature can supply a default for an omitted argument. That default
initializes the generated C variable. It does not add an argument to Perl's
stack. Code that reads `ST(n)` beyond `items` accesses an invalid argument,
even when the XS declaration supplies a default for that parameter.

JavaScript::QuickJS 0.21 declares two optional callbacks for
`Promise::then()`, both defaulting to `&PL_sv_undef`. Its implementation
ignores those C variables and passes `&ST(1)` to a converter that reads two
entries unconditionally. A call with fewer than two callbacks can therefore
read unrelated values or crash. The existing promise test crashes on the
tested XPerl v5.45.5 RC-stack build.

Use the initialized XS variables instead. When a helper expects an array,
construct a local array from those variables and pass it to the helper.
This fixes the invalid access for ordinary Perl and XPerl without a
`PERL_RC_STACK` or `XPERL_VERSION` condition. Do not invent stack entries for
missing arguments or rely on unused stack capacity containing undef.

Inspect XS signatures with optional defaults, nearby `PERL_UNUSED_ARG`
markers, direct `ST(n)` reads and helpers receiving `&ST(n)`. Establish the
actual argument count before assuming a stack slot exists. This is a source
review pattern, not proof that every such use is broken.

Test every supported arity and each callback outcome. QuickJS's regression
tests exercise zero, one and two callbacks on resolved and rejected
promises. Its complete suite passes 203 tests in 21 files on installed
unthreaded RC XPerl v5.45.5. The published patch also passes a fresh build
and installation without AI. Other interpreter profiles are untested.
