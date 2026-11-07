# Convert exception objects at text API boundaries

An XPerl catch may receive an `XPerl::Exception` object. If a library stores
that value in an API whose contract is text, later callers can mistake the
reference for a filehandle or another structured input. Inspect the consumer
before changing the producer.

At a text boundary, stringify the value explicitly and keep the existing
empty-value fallback. Preserve the exception object while it is being
propagated or queried. For example, an HTTP error response body should hold
the rendered error text, while the catch that builds it can inspect the
structured exception first.

The `libwww-perl` 6.83 patch makes its internal text response stringify a
caught error. It preserves scalar error text and tests a stringifiable
reference on ordinary Perl as well as XPerl.

The same applies when a caught value is stored in a field with a string type
constraint. `JSON-Schema-Modern` 0.652 passes `$e` from `catch ($e)` into an
error message typed `Str` at two sites. On XPerl the Type::Tiny check throws,
so a bad regex is reported as a generic exception and invalid JSON input dies
instead of returning a result. Stringifying `$e` at those two sites is enough;
its other catch blocks already concatenate, `chomp` or `sprintf` the value.
