# Distinguish XPerl's exception wrapper from user-thrown references

On XPerl, a caught ordinary string `die` is an `XPerl::Exception` in `$@`.
Code that treats every reference in `$@` as an explicitly thrown reference
may skip string-error handling. In `Params::Validate` 1.31, that bypasses the
context normally added to callback failures in both the Perl and XS paths.

When a module has separate handling for text errors and user-thrown
references, treat `XPerl::Exception` as a text error at that boundary while
preserving other references unchanged. Stringify the wrapper only when
building the module's public error message. In XS, use
`sv_derived_from(err, "XPerl::Exception")` under `#ifdef XPERL`; leave the
ordinary Perl branch intact. Use `SvPV` and its returned length for the
wrapper rather than assuming an RV has a useful `SvCUR` value.

Check that ordinary string callback errors gain the module's context, that
user-thrown hash references retain their identity, and that tests pass on
both XPerl and ordinary Perl. The `Params-Validate` 1.31 patch is an example.

The same distinction matters when formatting an error for test diagnostics.
`XPerl::Exception` stringifies to the legacy error text, so adding its class
name as if it were a user-thrown object changes expected diagnostics. The
`Test-Exception` 0.43 patch leaves named user exception classes visible while
rendering the XPerl wrapper as text.
