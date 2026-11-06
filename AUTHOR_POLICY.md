# Author policy and upstream patch queue

An author can state whether they will consider XPerl compatibility patches.
Repository 0 keeps that statement at `authors/A/AB/AUTHOR.json`, following
the CPAN author ID fanout. The record is independent of distribution
sharding, so one author has one policy even if their releases move to
different data repositories.

The `xperl_patches.status` value is `accepting` or `declined`. No author
record means the policy is unknown. A record also gives the confirmation
date and basis. The installer does not consult this policy when selecting
or applying patches.

After a patch has passed the release's tests, an accepting author can have
an upstream queue entry at
`upstream-queue/A/AB/AUTHOR/Distribution-Version-PatchSet.json`. The entry
names the original CPAN archive, source digest, patch set, patch digest,
upstream repository, and current state. `ready` means the patch is prepared
for the author to submit or review; it does not claim that an upstream PR
has been opened. When submitted, record the PR URL and move the state to
`submitted`. Record `merged` or `declined` when upstream resolves it.

Keep the queue entry tied to the exact patch digest. If the patch changes,
retest it and update the queue entry before submission.
