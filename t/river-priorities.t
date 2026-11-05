use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP qw(encode_json);

my $root = tempdir(CLEANUP => 1);
my $status_dir = File::Spec->catdir($root, 'status');
make_path($status_dir);
my $river_file = File::Spec->catfile($root, 'river.json');
write_file($river_file, encode_json({
    'Ported' => { immediate => 3, total => 20, bucket => 2 },
    'Blocked' => { immediate => 2, total => 15, bucket => 2 },
    'New' => { immediate => 1, total => 10, bucket => 2 },
}));
my $candidates_file = File::Spec->catfile($root, 'candidates.txt');
write_file($candidates_file, "Ported\nBlocked\nNew\n");

for my $entry (
    ['Ported', 'installed'],
    ['Blocked', 'failed'],
) {
    my ($distribution, $state) = @$entry;
    my $directory = File::Spec->catdir($status_dir, 'ab', 'AUTHOR',
                                      $distribution);
    make_path($directory);
    write_file(File::Spec->catfile($directory, 'status.json'),
        encode_json({
            schema => 2,
            author => 'AUTHOR',
            distribution => $distribution,
            observations => [{
                id => $distribution,
                observed_at => '2026-11-05T00:00:00Z',
                xperl_version => "$^V",
                status => $state,
                version => '1.0',
            }],
        }));
}

my $script = File::Spec->catfile($FindBin::Bin, '..', 'bin', 'river-priorities');
my @command = ($^X, $script, '--river', $river_file,
    '--candidates', $candidates_file, '--status-dir', $status_dir,
    '--pending', '--limit', 2);
open my $output, '-|', @command or die "cannot run report: $!";
my $report = do { local $/; <$output> };
close $output;
is($? >> 8, 0, 'report exits successfully');
unlike($report, qr/^Ported\t/m, 'pending report omits an installed release');
like($report, qr/^Blocked\tAUTHOR\t2\t15\tfailed\t1\.0$/m,
    'failed release keeps its version and river counts');
like($report, qr/^New\t-\t1\t10\tunobserved\t-$/m,
    'unobserved release follows the failed release');

done_testing;

sub write_file {
    my ($path, $data) = @_;
    open my $file, '>', $path or die "$path: $!";
    print {$file} $data;
    close $file or die "$path: $!";
}
