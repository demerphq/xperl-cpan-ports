# Use XPerl's diagnostic error count in parser XS

Ordinary Perl stores compile error count in the parser structure. XPerl
tracks it in the pending structured exception instead, so XS code that reads
or increments the parser field no longer compiles. XPerl exposes
PERL_DIAG_ERROR_COUNT in perl.h for checking the current count.

Keep the ordinary Perl parser field path under the non-XPerl branch. Under
XPERL_VERSION, read PERL_DIAG_ERROR_COUNT. Do not increment the old parser
field before croak_sv in XPerl: fatal diagnostic delivery updates the pending
exception. Check every read and write of the old field in the distribution,
including keyword and infix plugin callbacks.

XS-Parse-Keyword 0.51 is a worked example. After the conditional port, its
25 test files and 195 tests pass on XPerl v5.45.5. XS-Parse-Sublike 0.42
needs the same count substitution in both its XS entry point and parser
source. Its private yyerror replacement increments the old field and warns;
under XPerl it instead calls croak_sv so a syntax error terminates parsing.
Its 29 test files and 123 tests pass. Test both successful parses and
syntax-error paths, because the count controls whether a plugin continues
parsing after an error.
