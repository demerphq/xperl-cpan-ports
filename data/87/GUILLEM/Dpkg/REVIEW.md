# Dpkg 1.23.9: taint tests, reconfiguration and installation paths

The Popcon top-100 batch exposed two general build and test issues:

- Taint-mode child interpreters ignore `PERL5LIB`. Pass `-Ilib` explicitly
  so syntax checks can load the distribution's own modules.
- Path tests create a recursive symlink in the generated `t.tmp` tree.
  Remove that tree before configuration's manifest scan follows it.

The consolidated patch preserves both fixes against the original CPAN
archive. It contains no XPerl-specific code and no RC-stack changes.
Upstream access limitations and checked references are retained in its
evidence. The cleanup was checked against a symlink pointing outside the
test tree and preserved the outside target.

All 13,252 checks in 60 test programs pass using installed XPerl v5.45.5,
commit `8903238ce74fc124ec407b8342791ef73253f988`, x86_64 Linux,
GCC 13.3.0, `PERL_RC_STACK`, no threads, multiplicity or debugging,
double NV, without longdouble or quadmath. A fresh extraction applies the
registered patch, builds, tests and installs without an AI worker. Other
interpreter profiles and ordinary Perl are untested.

The repair agent's sandbox prevents `gpg-agent` socket creation, causing
six OpenPGP checks to fail there. Those checks pass in the installer's
normal build environment. The patch does not skip or weaken them.

## Keep package data inside the selected prefix

Dpkg's CPAN build declares extra installation elements with system paths.
Use Module::Build's supported `install_path` arguments when installing an
isolated copy. The source patch contains no local installation paths.

```toml
schema = 1

[install.configure_args]
"GUILLEM/Dpkg" = [
    "--install_path", "conf={prefix}/etc/dpkg",
    "--install_path", "data={prefix}/share/dpkg",
    "--install_path", "admin={prefix}/var/lib/dpkg",
    "--install_path", "libexec={prefix}/lib/dpkg",
]
```

The tested interpreter uses its normal site-library layout for Perl modules.
Configuration and package data use the paths above. This does not replace
the operating system's dpkg installation or package database.
