# Extract source archives without launching a terminal

Some self-extracting source archives try to open a graphical terminal when
stdout is not a terminal and `DISPLAY` is set. An unattended CPAN build can
then fail before extraction, even though no interaction is needed.

Check the archive's documented extraction options. If it supports a
headless mode, pass that option at the distribution's extraction call.
Avoid changing the installer's global display environment to accommodate
one archive. Confirm that extraction leaves the expected build files, then
run the distribution's full build and test cycle.

Alien-Xmake v1.0.5 downloads a Makeself xmake archive. Its `--noexec`
option stops the bundled setup script, but does not stop Makeself from
launching `gnome-terminal`. Its `--nox11` option does. Adding that option
to Alien-Xmake's extraction command lets xmake build and all 31 tests pass.
