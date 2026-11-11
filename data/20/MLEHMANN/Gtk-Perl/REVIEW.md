# Gtk-Perl 0.7010: blocked on legacy GTK+ 1.2

The River top-500 batch reaches configuration but cannot execute
`gtk-config`. This release needs GTK+ 1.2 and matching GLib 1.2 development
files. GTK 2 and GTK 3 development packages provide different APIs and do
not satisfy that requirement.

The tested Linux Mint 22.3 / Ubuntu noble package repositories offer no
`libgtk1.2-dev` or `libglib1.2-dev` candidate. A maintained compatibility
environment would need to supply those libraries and their X11 development
prerequisites. The historical source is available from the
[GTK+ 1.2 archive](https://download.gnome.org/sources/gtk%2B/1.2/).

Before retrying, verify that `gtk-config --version` reports 1.2.x and
`gtk-config --cflags --libs` identifies usable headers and libraries. Do not
bypass detection with `--with-gtk-force` or substitute newer GTK tooling.

No source patch was generated. Configuration failed before XS compilation,
so neither a source incompatibility nor working runtime support has been
established. This is a missing legacy system dependency, not a demonstrated
XPerl defect.

The recorded interpreter is installed XPerl v5.45.5, commit
`8903238ce74fc124ec407b8342791ef73253f988`, x86_64 Linux, GCC 13.3.0,
`PERL_RC_STACK`, no threads, no multiplicity, no debugging, double NV,
without longdouble or quadmath. The failed observations are in
[status.json](status.json). The remaining module is retained in the
[River queue](../../../../queues/river-top500-2026-11-11.txt).
