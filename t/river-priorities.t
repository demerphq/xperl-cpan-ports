use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP qw(encode_json);
use Config;

my $root = tempdir(CLEANUP => 1);
my $status_dir = File::Spec->catdir($root, 'status');
make_path($status_dir);
my $river_file = File::Spec->catfile($root, 'river.json');
write_file($river_file, encode_json({
    'Ported' => { immediate => 3, total => 20, bucket => 2 },
    'Blocked' => { immediate => 2, total => 15, bucket => 2 },
    'New' => { immediate => 1, total => 10, bucket => 2 },
    'Bundled' => { immediate => 1, total => 12, bucket => 2 },
}));
my $candidates_file = File::Spec->catfile($root, 'candidates.txt');
write_file($candidates_file, "Ported\nBlocked\nNew\nBundled\n");
my $bundled_file = File::Spec->catfile($root, 'bundled.json');
write_file($bundled_file, encode_json({
    schema => 1, xperl_version => "$^V", distributions => ['Bundled'],
}));

for my $entry (
    ['Ported', 'installed'],
    ['Blocked', 'failed'],
) {
    my ($distribution, $state) = @$entry;
    my $directory = File::Spec->catdir($status_dir, 'ab', 'AUTHOR',
                                      $distribution);
    make_path($directory);
    my @observations = ({
        id => $distribution,
        observed_at => '2026-11-05T00:00:00Z',
        xperl_version => "$^V",
        status => $state,
        platform => { key => "$^O/$Config{archname}" },
        version => '1.0',
    });
    push @observations, {
        id => 'other-platform',
        observed_at => '2026-11-06T00:00:00Z',
        xperl_version => "$^V",
        status => 'failed',
        platform => { key => 'other/arch' },
        version => '1.0',
    } if $distribution eq 'Ported';
    write_file(File::Spec->catfile($directory, 'status.json'),
        encode_json({
            schema => 2,
            author => 'AUTHOR',
            distribution => $distribution,
            observations => \@observations,
        }));
}

my $script = File::Spec->catfile($FindBin::Bin, '..', 'bin', 'river-priorities');
my @command = ($^X, $script, '--river', $river_file,
    '--candidates', $candidates_file, '--status-dir', $status_dir,
    '--bundled-file', $bundled_file,
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
unlike($report, qr/^Bundled\t/m,
    'pending report omits a bundled distribution');

open $output, '-|', @command[0 .. $#command - 3], '--limit', 4
    or die "cannot run full report: $!";
$report = do { local $/; <$output> };
close $output;
like($report, qr/^Bundled\t-\t1\t12\tbundled-with-xperl\t-$/m,
    'full report labels the XPerl bundle');

done_testing;

sub write_file {
    my ($path, $data) = @_;
    open my $file, '>', $path or die "$path: $!";
    print {$file} $data;
    close $file or die "$path: $!";
}
