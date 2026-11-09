# Native-source RC replay coverage

`coverage.json` records the source and patch digests, target interpreter build,
native-source signatures and matching RC validations. Missing cached archives
are unknown, not assumed pure Perl. Signatures include optional XS and do not
prove that a particular build compiled the extension.

`replay.txt` contains author/distribution keys for `install-ported --from`.
That command forces each selected recorded root to build and test even if
already installed. Dependencies follow normal installed-version checks.
Use four build workers and one repair worker. Deferred entries are omitted.

Run with the installed RC XPerl and the normal shared download cache:

```sh
"$rc_perl" "$rc_prefix/bin/xperl-install" install-ported \
    --prefix "$rc_prefix" --registry "$PWD/xperl-cpan-ports" \
    --from "$PWD/xperl-cpan-ports/queues/rc-xs-linux/replay.txt" \
    --workdir "$PWD/tmp/rc-xs-replay" \
    --jobs 4 --repair-jobs 1 --agent codex
```

Regenerate after recording new results using the same `planning/rc-xs-coverage`
command and target interpreter. Changed build identities or patches require
their own validation. Do not treat a queued distribution as a known failure.
