# Test dependency version ranges

An exact test prerequisite can reject an installed newer version even when
the tests work with that version. The installer should report the conflict
without fetching the same indexed release or attempting an impossible build.

Inspect the tests and the author's dependency policy before changing the
constraint. Exact pins may be deliberate for development reproducibility.
If the tests work with the newer installed version, a compatibility patch
can use the pinned version as its lower bound without claiming that the
author supports all later releases. Keep the source `cpanfile` and generated
`META.json` and `META.yml` consistent. Run the full distribution tests with
the installed newer dependency.

App-Gimei v0.3.2 pins `Test2::V1` to 1.302225 for tests. XPerl v5.45.5
bundles 1.302226. The tests pass with a minimum of 1.302225, so its patch
changes the three declarations to `>= 1.302225`.

App-Gimei's v0.2.10 changelog says the author fixed module versions in
`cpanfile`. Its development guide uses Carton in deployment mode, and the
v0.3.2 release pins nearly every dependency. The Test2 patch is a tested
XPerl compatibility override of that policy, not evidence that the exact
pin was accidental.
