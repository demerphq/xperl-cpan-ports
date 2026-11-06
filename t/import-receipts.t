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

$receipt->{status} = 'installed';
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
my $prefix = unpack 'H2', siphash_2_4('AUTHOR/Example-Feature', "\0" x 16);
my $status_path = File::Spec->catfile($root, 'data', $prefix, 'AUTHOR',
                                     'Example-Feature', 'status.json');
my $status = JSON::PP->new->decode(read_file($status_path));
is($status->{author}, 'AUTHOR', 'status is scoped to the CPAN author');
is(scalar @{$status->{observations}}, 2, 'both outcomes remain recorded');
is($status->{observations}[0]{version}, '2.0',
   'distribution release version comes from archive');
is($status->{observations}[0]{module_version}, '1.0',
   'different module version is retained');
is(system($^X, $script, '--cache', File::Spec->catdir($root, 'success')),
   0, 'repeat import succeeds');
$status = JSON::PP->new->decode(read_file($status_path));
is(scalar @{$status->{observations}}, 2, 'repeat import is idempotent');
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
