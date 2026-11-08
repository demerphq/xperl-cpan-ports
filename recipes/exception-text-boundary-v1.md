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

A serializer is also a text boundary. `Dancer2-Plugin-GraphQL` 0.09 puts `$@`
from a failed handler straight into the `message` of a GraphQL error and
sends the result as JSON. On XPerl `Cpanel::JSON::XS` refuses to encode the
exception object, so the client gets an empty body instead of the error.
Stringifying `$@` where the error hash is built is enough.

Patching a module can also start an author-only build rule. Its `Makefile.PL`
regenerates `README.md` from the module with `pod2markdown` whenever the `.pm`
is newer, and a patched file always is. The patch set limits that rule to a
git checkout so release builds do not need the tool.
