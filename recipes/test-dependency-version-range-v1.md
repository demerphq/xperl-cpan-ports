# Test dependency version ranges

An exact test prerequisite can reject an installed newer version even when
the tests work with that version. The installer should report the conflict
without fetching the same indexed release or attempting an impossible build.

Inspect the tests before changing the constraint. If they use ordinary APIs
that work with the newer version, replace the exact pin with the earliest
version the author intended to support. Keep the source `cpanfile` and
generated `META.json` and `META.yml` consistent. Run the full distribution
tests with the installed newer dependency.

App-Gimei v0.3.2 pins `Test2::V1` to 1.302225 for tests. XPerl v5.45.5
bundles 1.302226. The tests pass with a minimum of 1.302225, so its patch
changes the three declarations to `>= 1.302225`.
