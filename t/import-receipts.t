use strict;
use warnings;
use builtin qw(siphash_2_4);
no warnings 'experimental::builtin';
use Test::More;
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP;

my $root = tempdir(CLEANUP => 1);
my $bin = File::Spec->catdir($root, 'bin');
my $failure = File::Spec->catdir($root, 'failure', 'work', 'release-a');
my $success = File::Spec->catdir($root, 'success', 'work', 'release-b');
make_path($bin, $failure, $success);
my $script = File::Spec->catfile($bin, 'import-receipts');
ok(copy(File::Spec->catfile($FindBin::Bin, '..', 'bin', 'import-receipts'),
        $script), 'copied importer into isolated registry');
ok(copy(File::Spec->catfile($FindBin::Bin, '..', 'registry.json'),
        File::Spec->catfile($root, 'registry.json')),
   'copied bootstrap configuration');

my $receipt = {
    module => 'Example::Feature',
    version => '1.0',
    cpan_path => 'A/AU/AUTHOR/older/Example-Feature-2.0.tar.gz',
    source_sha256 => 'a' x 64,
    xperl_version => 'v5.45.5',
    status => 'failed',
    phases => [{ name => 'build', exit_status => 2 }],
};
my $failed_receipt = File::Spec->catfile($failure, 'receipt.json');
write_json($failed_receipt, $receipt);
utime(time - 20, time - 20, $failed_receipt);
is(system($^X, $script, '--cache', File::Spec->catdir($root, 'failure')),
   0, 'failure import succeeds');
my $unresolved = read_file(File::Spec->catfile($root, 'status',
                                               'UNRESOLVED.md'));
like($unresolved, qr/Example-Feature.*build/, 'failure is indexed');

my $prefix = unpack 'H2', siphash_2_4('AUTHOR/Example-Feature', "\0" x 16);
my $status_path = File::Spec->catfile($root, 'data', $prefix, 'AUTHOR',
                                     'Example-Feature', 'status.json');
my $triage_status = JSON::PP->new->decode(read_file($status_path));
$triage_status->{triage} = {
    version => '2.0', source_sha256 => 'a' x 64,
    disposition => 'out-of-date-with-blead',
    reason => 'This release uses removed Perl internals.',
};
write_json($status_path, $triage_status);
is(system($^X, $script, '--rebuild'), 0,
   'summary rebuild preserves release triage');
$unresolved = read_file(File::Spec->catfile($root, 'status', 'UNRESOLVED.md'));
like($unresolved, qr/Example-Feature.*out-of-date-with-blead/,
     'unresolved report shows the release disposition');

$receipt->{status} = 'installed';
$receipt->{registry} = {
    patch_set => 'cve-2024-45321-https-defaults',
    purpose => 'security',
    advisories => ['CVE-2024-45321'],
    patches => ['a' x 64],
};
$receipt->{phases} = [
    { name => 'build', exit_status => 0 },
    { name => 'test', exit_status => 0 },
    { name => 'install', exit_status => 0 },
];
my $success_receipt = File::Spec->catfile($success, 'receipt.json');
write_json($success_receipt, $receipt);
utime(time - 10, time - 10, $success_receipt);
is(system($^X, $script, '--cache', File::Spec->catdir($root, 'success')),
   0, 'successful retry import succeeds');
$unresolved = read_file(File::Spec->catfile($root, 'status',
                                            'UNRESOLVED.md'));
unlike($unresolved, qr/Example-Feature.*build/,
       'successful retry resolves the failure');
my $status = JSON::PP->new->decode(read_file($status_path));
is($status->{author}, 'AUTHOR', 'status is scoped to the CPAN author');
is($status->{triage}{disposition}, 'out-of-date-with-blead',
   'later receipt import retains release triage');
my $triaged_summary = read_file(File::Spec->catfile($root, 'status',
                                                    'SUMMARY.md'));
like($triaged_summary, qr/Example-Feature.*installed \(out-of-date-with-blead\)/,
     'summary keeps release triage visible after installation');
is(scalar @{$status->{observations}}, 2, 'both outcomes remain recorded');
my ($secured) = grep { $_->{status} eq 'installed' }
    @{$status->{observations}};
is($secured->{patch_purpose}, 'security', 'security purpose is recorded');
is_deeply($secured->{advisories}, ['CVE-2024-45321'],
          'security advisory is recorded');
is($status->{observations}[0]{version}, '2.0',
   'distribution release version comes from archive');
is($status->{observations}[0]{module_version}, '1.0',
   'different module version is retained');
my $status_mtime = time - 30;
utime($status_mtime, $status_mtime, $status_path);
is(system($^X, $script, '--cache', File::Spec->catdir($root, 'success')),
   0, 'repeat import succeeds');
$status = JSON::PP->new->decode(read_file($status_path));
is(scalar @{$status->{observations}}, 2, 'repeat import is idempotent');
is((stat($status_path))[9], $status_mtime,
   'unchanged status is not rewritten');

my $first_success_time = $secured->{observed_at};
my $repeat = File::Spec->catdir($root, 'repeat', 'work', 'release-e');
make_path($repeat);
$receipt->{run_nonce} = 'a separate build with the same result';
my $repeat_receipt = File::Spec->catfile($repeat, 'receipt.json');
write_json($repeat_receipt, $receipt);
utime(time, time, $repeat_receipt);
is(system($^X, $script, '--cache', File::Spec->catdir($root, 'repeat')),
   0, 'identical result from another receipt imports');
$status = JSON::PP->new->decode(read_file($status_path));
is(scalar @{$status->{observations}}, 2,
   'same build facts do not create another observation');
my ($kept_success) = grep { $_->{status} eq 'installed' }
    @{$status->{observations}};
is($kept_success->{observed_at}, $first_success_time,
   'repeated result does not update the original observation time');
is((stat($status_path))[9], $status_mtime,
   'identical build facts do not rewrite the status');

is(system($^X, $script, '--rebuild'), 0,
   'summary can be rebuilt without importing receipts');
my $other = File::Spec->catdir($root, 'other', 'work', 'release-c');
make_path($other);
$receipt->{cpan_path} = 'B/BO/BOB/Example-Feature-2.0.tar.gz';
write_json(File::Spec->catfile($other, 'receipt.json'), $receipt);
is(system($^X, $script, '--cache', File::Spec->catdir($root, 'other')),
   0, 'same distribution from another author imports');
my $other_prefix = unpack 'H2',
    siphash_2_4('BOB/Example-Feature', "\0" x 16);
my $other_path = File::Spec->catfile($root, 'data', $other_prefix, 'BOB',
                                    'Example-Feature', 'status.json');
ok(-f $other_path, 'other author has a separate status record');
is(scalar @{JSON::PP->new->decode(read_file($status_path))->{observations}}, 2,
   'first author retains its observations');

# A result from another platform for the same release and XPerl version is
# recorded beside the earlier result instead of replacing it.
my $mac = File::Spec->catdir($root, 'mac', 'work', 'release-d');
make_path($mac);
$receipt->{cpan_path} = 'A/AU/AUTHOR/older/Example-Feature-2.0.tar.gz';
$receipt->{status} = 'failed';
$receipt->{phases} = [{ name => 'test', exit_status => 1 }];
$receipt->{platform} = {
    key => 'darwin/darwin-2level', os => 'darwin', osvers => '25.6.0',
    archname => 'darwin-2level', cc => 'cc', cc_version => 'clang 21',
    make => 'make', usethreads => 0, use64bitall => 1,
    xperl_commit => 'b' x 40,
};
write_json(File::Spec->catfile($mac, 'receipt.json'), $receipt);
is(system($^X, $script, '--cache', File::Spec->catdir($root, 'mac')),
   0, 'result from another platform imports');
$status = JSON::PP->new->decode(read_file($status_path));
my ($mac_observation) =
    grep { ($_->{platform}{key} // '') eq 'darwin/darwin-2level' }
    @{$status->{observations}};
ok($mac_observation, 'observation records its platform');
is($mac_observation->{platform}{cc_version}, 'clang 21',
   'platform details are retained');
my $summary = read_file(File::Spec->catfile($root, 'status', 'SUMMARY.md'));
like($summary, qr/\| AUTHOR \| \[Example-Feature\].* \| 2\.0 \| v5\.45\.5 \| unrecorded \| installed \(out-of-date-with-blead\) \|/,
     'earlier result without a platform keeps its own summary row');
like($summary, qr/\| AUTHOR \| \[Example-Feature\].* \| 2\.0 \| v5\.45\.5 \| darwin\/darwin-2level \| failed \(out-of-date-with-blead\) \|/,
     'new platform has a separate summary row');
$unresolved = read_file(File::Spec->catfile($root, 'status', 'UNRESOLVED.md'));
like($unresolved, qr/Example-Feature.*darwin\/darwin-2level.*test/,
     'platform failure is unresolved for that platform only');

# Observations imported before receipts recorded a platform can be assigned
# one when it is known; observations that have a platform keep it.
is(system($^X, $script, '--rebuild', '--assume-platform', 'linux/x86_64-linux'),
   0, 'backfill of unrecorded platforms succeeds');
$status = JSON::PP->new->decode(read_file($status_path));
my %keys;
$keys{$_->{platform}{key} // 'none'}++ for @{$status->{observations}};
is_deeply(\%keys, { 'linux/x86_64-linux' => 2, 'darwin/darwin-2level' => 1 },
          'only observations without a platform are backfilled');
my ($linux) = grep { $_->{platform}{key} eq 'linux/x86_64-linux' }
    @{$status->{observations}};
is_deeply($linux->{platform},
          { key => 'linux/x86_64-linux', os => 'linux', archname => 'x86_64-linux' },
          'backfilled platform derives its OS and architecture from the key');
$summary = read_file(File::Spec->catfile($root, 'status', 'SUMMARY.md'));
unlike($summary, qr/\| unrecorded \|/, 'no unrecorded rows remain');
isnt(system($^X, $script, '--rebuild', '--assume-platform', 'not a key'), 0,
     'a malformed platform key is rejected');

# A repair registered during installation takes precedence over patches
# selected before the repair began.
my $repair_dir = File::Spec->catdir($root, 'repair', 'work', 'release-e');
make_path($repair_dir);
$receipt->{cpan_path} = 'C/CH/CHARLIE/Example-Repair-1.0.tar.gz';
$receipt->{status} = 'installed';
$receipt->{registration} = {
    status => 'registered', patch_set => 'repair-v5.45.5',
    patch_sha256 => 'c' x 64,
};
$receipt->{registry} = { patch_set => undef, patches => [] };
$receipt->{phases} = [{ name => 'test', exit_status => 0 },
                     { name => 'install', exit_status => 0 }];
write_json(File::Spec->catfile($repair_dir, 'receipt.json'), $receipt);
is(system($^X, $script, '--cache', File::Spec->catdir($root, 'repair')),
   0, 'newly registered repair imports');
my $repair_prefix = unpack 'H2',
    siphash_2_4('CHARLIE/Example-Repair', "\0" x 16);
my $repair_path = File::Spec->catfile($root, 'data', $repair_prefix,
                                     'CHARLIE', 'Example-Repair', 'status.json');
my $repair_status = JSON::PP->new->decode(read_file($repair_path));
my $repaired = $repair_status->{observations}[0];
is($repaired->{patch_set}, 'repair-v5.45.5',
   'status names the registered repair patch');
is_deeply($repaired->{patch_sha256}, ['c' x 64],
          'status keeps the registered patch digest');
done_testing();

sub write_json {
    my ($path, $data) = @_;
    open my $file, '>', $path or die "$path: $!";
    print {$file} JSON::PP->new->canonical->encode($data);
    close $file or die "$path: $!";
}

sub read_file {
    my ($path) = @_;
    open my $file, '<', $path or die "$path: $!";
    local $/;
    return <$file>;
}
