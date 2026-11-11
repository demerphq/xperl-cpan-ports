# Gtk-Perl 0.7010: obsolete and superseded

Defer this release and remove it from active repair work. Gtk-Perl binds
GTK+ 1.x. Gtk2 and Gtk3 are successor bindings, with different APIs.
The project's [porting guide](https://gtk2-perl.sourceforge.net/doc/porting.html)
explains the rewrite and the application changes needed to migrate.
We are not pursuing restoration of its GTK+ 1.2 environment.

## Recorded build failure

The River top-500 batch reaches configuration but cannot execute
`gtk-config`. This release needs GTK+ 1.2 and matching GLib 1.2 development
files. GTK 2 and GTK 3 development packages provide different APIs and do
not satisfy that requirement.

The tested Linux Mint 22.3 / Ubuntu noble package repositories offer no
`libgtk1.2-dev` or `libglib1.2-dev` candidate. A maintained compatibility
environment would need to supply those libraries and their X11 development
prerequisites. The historical source is available from the
[GTK+ 1.2 archive](https://download.gnome.org/sources/gtk%2B/1.2/).

If legacy support is revisited, verify that `gtk-config --version` reports
1.2.x and `gtk-config --cflags --libs` identifies usable headers and
libraries. Do not bypass detection with `--with-gtk-force` or substitute
newer GTK tooling.

No source patch was generated. Configuration failed before XS compilation,
so neither a source incompatibility nor working runtime support has been
established. This is a missing legacy system dependency, not a demonstrated
XPerl defect.

The recorded interpreter is installed XPerl v5.45.5, commit
`8903238ce74fc124ec407b8342791ef73253f988`, x86_64 Linux, GCC 13.3.0,
`PERL_RC_STACK`, no threads, no multiplicity, no debugging, double NV,
without longdouble or quadmath. The failed observations are in
[status.json](status.json), with an `obsolete-superseded` triage disposition.
The [River batch report](../../../../queues/river-top500-2026-11-11.md)
retains this deferred target without counting it as installed.

## River dependency attribution

The 2026-11-11 River snapshot ranks Gtk-Perl 328th, with 165 immediate
and 951 total downstream distributions. Those figures do not establish
that all those distributions need GTK+ 1.x.

The [River calculator](https://github.com/metacpan/metacpan-river/blob/main/bin/river.pl)
assigns module providers while scanning latest releases. When several
distributions provide the same module, the last scanned provider wins.
It does not consult the canonical CPAN package index for that choice.
Gtk-Perl bundles `ExtUtils::Depends`, which has its own current distribution.
This can attribute consumers of the build utility to the obsolete GTK
distribution and likely explains its inflated ranking.

On 2026-11-11, a MetaCPAN release search for prerequisites naming any of
the 36 modules canonically mapped to Gtk-Perl by `02packages.details.txt.gz`
finds one latest distribution: `POE-Loop-Gtk` 1.306, released 2013-08-21.
It requires `Gtk` 0.7009 at runtime. The query covers the runtime,
configure, build and test `requires` relationships used by River. It does
not detect undeclared or dynamically computed dependencies and does not
recalculate the transitive graph.
