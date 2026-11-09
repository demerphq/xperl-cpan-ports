# Review queues

This directory holds CPAN distributions selected for investigation before we
have a build result. A queue is a worklist, not evidence that a distribution
fails on XPerl. Keep build and test observations in the distribution's
`status.json` under `data/`, including unsuccessful attempts.

Each `.txt` file is an input to `xperl-install install --from FILE`. Put one
module name on each line. Blank lines and text after `#` are ignored by the
installer, so use comments to record the source, reason, and any uncertainty.
Name the queue for the investigation, and keep related candidates together.

After attempting a candidate, record the result in `data/` through the normal
receipt import and patch registration workflow. Keep a failing candidate in
the queue while it needs review. Remove it when its result has been triaged and
the next action is tracked in its distribution record or patch proposal.

The [RC native-source queue](rc-xs-linux/README.md) uses author/distribution
keys for `install-ported --from`, which forces recorded releases to rebuild
even when their modules are already installed. Its coverage report separates
current-build validation, other RC builds, deferred work and unknown sources.
Follow that queue's README instead of passing its keys to ordinary `install`.

The `upstream-queue/` directory has a different purpose: it tracks patches
ready to propose to CPAN authors.
