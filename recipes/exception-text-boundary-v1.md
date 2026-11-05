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
