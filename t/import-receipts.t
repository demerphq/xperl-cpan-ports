use strict;
use warnings;
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

my $receipt = {
    module => 'Example::Feature',
    version => '1.0',
    cpan_path => 'A/AB/AUTHOR/Example-Feature-2.0.tar.gz',
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
my $status_path = File::Spec->catfile($root, 'status', 'distributions',
                                     'Example-Feature.json');
my $status = JSON::PP->new->decode(read_file($status_path));
is(scalar @{$status->{observations}}, 2, 'both outcomes remain recorded');
is($status->{observations}[0]{version}, '2.0',
   'distribution release version comes from archive');
is($status->{observations}[0]{module_version}, '1.0',
   'different module version is retained');
is(system($^X, $script, '--cache', File::Spec->catdir($root, 'success')),
   0, 'repeat import succeeds');
$status = JSON::PP->new->decode(read_file($status_path));
is(scalar @{$status->{observations}}, 2, 'repeat import is idempotent');
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
