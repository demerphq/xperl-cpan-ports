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

# --receipt FILE imports named receipts; --record-only updates only their
# distribution records and leaves the generated summary pages alone, so a
# publisher can record one completed distribution without rescanning the
# whole registry.

my $root = tempdir(CLEANUP => 1);
my $bin = File::Spec->catdir($root, 'bin');
make_path($bin);
my $script = File::Spec->catfile($bin, 'import-receipts');
ok(copy(File::Spec->catfile($FindBin::Bin, '..', 'bin', 'import-receipts'),
        $script), 'copied importer into isolated registry');
ok(copy(File::Spec->catfile($FindBin::Bin, '..', 'registry.json'),
        File::Spec->catfile($root, 'registry.json')),
   'copied bootstrap configuration');

my $base = {
    module => 'Example::Base',
    cpan_path => 'A/AU/AUTHOR/Example-Base-1.0.tar.gz',
    source_sha256 => 'a' x 64,
    xperl_version => 'v5.45.5',
    status => 'installed',
    platform => {
        key => 'darwin/darwin-2level', os => 'darwin',
        archname => 'darwin-2level', build_id => 'b' x 64,
        build => { schema => 1, rc_stack => 1 },
    },
    registry => { patch_set => undef, patches => [] },
    phases => [{ name => 'test', exit_status => 0 },
               { name => 'install', exit_status => 0 }],
};
my $base_receipt = receipt_file('base', $base);
is(run('--receipt', $base_receipt), 0,
   '--receipt without --record-only imports and regenerates summaries');
my $summary_path = File::Spec->catfile($root, 'status', 'SUMMARY.md');
my $unresolved_path = File::Spec->catfile($root, 'status', 'UNRESOLVED.md');
like(read_file($summary_path), qr/Example-Base/,
     'normal receipt import lists the release in the summary');
my $base_status = status_path('AUTHOR', 'Example-Base');
ok(-f $base_status, 'normal receipt import writes the status record');

# Usage errors.
isnt(run('--record-only'), 0, '--record-only requires --receipt');
isnt(run('--record-only', '--receipt', $base_receipt, '--cache', $root), 0,
     '--record-only rejects --cache');
isnt(run('--record-only', '--receipt', $base_receipt, '--rebuild'), 0,
     '--record-only rejects --rebuild');
isnt(run('--record-only', '--receipt', $base_receipt,
         '--assume-platform', 'linux/x86_64-linux'), 0,
     '--record-only rejects --assume-platform');
isnt(run('--receipt', File::Spec->catfile($root, 'missing.json')), 0,
     'a missing receipt file is an error');

# A failed result with a registered repair candidate, a build identity and
# patch digests, for a new distribution. A broken unrelated status record
# proves record-only mode does not scan the rest of the registry.
my $broken = status_path('ZED', 'Broken-Record');
make_path(File::Spec->catpath('', (File::Spec->splitpath($broken))[1], ''));
write_raw($broken, "{ this is not json\n");
isnt(run('--rebuild'), 0, 'a full rebuild reads every record (and fails here)');

my $summary_before = read_file($summary_path);
my $unresolved_before = read_file($unresolved_path);
my $old = time - 100;
utime($old, $old, $summary_path, $unresolved_path, $base_status);

my $failed = {
    %$base,
    module => 'Example::Repair',
    cpan_path => 'C/CH/CHARLIE/Example-Repair-2.0.tar.gz',
    source_sha256 => 'c' x 64,
    status => 'failed',
    registry => { patch_set => 'xperl-fix', patches => ['d' x 64] },
    phases => [{ name => 'test', exit_status => 2 }],
};
my $failed_receipt = receipt_file('failed', $failed);
my $installed = {
    %$base,
    module => 'Example::Other',
    cpan_path => 'O/OT/OTHER/Example-Other-0.5.tar.gz',
    source_sha256 => 'e' x 64,
};
my $installed_receipt = receipt_file('other', $installed);
is(run('--record-only', '--receipt', $failed_receipt,
       '--receipt', $installed_receipt), 0,
   'record-only imports repeated --receipt files without touching other records');

my $repair_status = status_path('CHARLIE', 'Example-Repair');
my $other_status = status_path('OTHER', 'Example-Other');
ok(-f $repair_status && -f $other_status, 'both named distributions are recorded');
my $repair = decode(read_file($repair_status));
my ($observation) = @{$repair->{observations}};
is($observation->{status}, 'failed', 'the failure is preserved');
is_deeply($observation->{failure}, { phase => 'test', exit_status => 2 },
          'the failed phase is recorded');
is($observation->{platform}{build_id}, 'b' x 64, 'the build identity is preserved');
is($observation->{platform}{build}{rc_stack}, 1, 'the build profile is preserved');
is($observation->{patch_set}, 'xperl-fix', 'the patch set is preserved');
is_deeply($observation->{patch_sha256}, ['d' x 64], 'patch digests are preserved');
unlike(read_file($repair_status), qr/\Q$root\E/, 'no local paths are recorded');

is(read_file($summary_path), $summary_before, 'SUMMARY.md is untouched');
is(read_file($unresolved_path), $unresolved_before, 'UNRESOLVED.md is untouched');
is((stat($summary_path))[9], $old, 'SUMMARY.md is not rewritten');
is((stat($base_status))[9], $old, 'an unrelated status record is not rewritten');

# Reimporting the same receipt, or a different receipt with the same facts,
# leaves the record byte-identical.
my $recorded = read_file($repair_status);
utime($old, $old, $repair_status);
is(run('--record-only', '--receipt', $failed_receipt), 0,
   'reimporting an identical receipt succeeds');
is(read_file($repair_status), $recorded, 'identical receipt leaves the record unchanged');
is((stat($repair_status))[9], $old, 'identical receipt does not rewrite the record');

my $same_facts = receipt_file('same-facts', { %$failed, run_nonce => 'another run' });
is(run('--record-only', '--receipt', $same_facts), 0,
   'a receipt with the same build facts imports');
is(read_file($repair_status), $recorded,
   'semantically identical facts add no observation and leave the record unchanged');

# A changed outcome for the same release is a new fact.
my $fixed = receipt_file('fixed', { %$failed, status => 'installed',
    phases => [{ name => 'test', exit_status => 0 },
               { name => 'install', exit_status => 0 }] });
utime(time + 5, time + 5, $fixed);
is(run('--record-only', '--receipt', $fixed), 0, 'a changed outcome imports');
$repair = decode(read_file($repair_status));
is_deeply([map { $_->{status} } @{$repair->{observations}}], [qw(failed installed)],
          'the earlier failure is kept beside the later success');
is(read_file($summary_path), $summary_before, 'SUMMARY.md is still untouched');

done_testing();

sub run { system($^X, $script, @_) }

sub receipt_file {
    my ($name, $data) = @_;
    my $dir = File::Spec->catdir($root, 'work', "release-$name");
    make_path($dir);
    my $path = File::Spec->catfile($dir, 'receipt.json');
    write_raw($path, JSON::PP->new->canonical->encode($data));
    return $path;
}

sub status_path {
    my ($author, $distribution) = @_;
    my $prefix = unpack 'H2', siphash_2_4("$author/$distribution", "\0" x 16);
    return File::Spec->catfile($root, 'data', $prefix, $author, $distribution,
                               'status.json');
}

sub decode { JSON::PP->new->decode($_[0]) }

sub write_raw {
    my ($path, $data) = @_;
    open my $file, '>', $path or die "$path: $!";
    print {$file} $data;
    close $file or die "$path: $!";
}

sub read_file {
    my ($path) = @_;
    open my $file, '<', $path or die "$path: $!";
    local $/;
    return <$file>;
}
