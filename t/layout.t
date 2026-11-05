use strict;
use warnings;
use builtin qw(siphash_2_4);
no warnings 'experimental::builtin';
use Digest::SHA qw(sha256_hex);
use File::Basename qw(basename dirname);
use File::Find qw(find);
use File::Spec;
use FindBin;
use JSON::PP;
use Test::More;

my $root = File::Spec->catdir($FindBin::Bin, '..');
my $data_dir = File::Spec->catdir($root, 'data');
my ($indexes, $statuses) = (0, 0);

find({
    no_chdir => 1,
    wanted => sub {
        return unless -f $File::Find::name;
        my $path = $File::Find::name;
        my $name = basename($path);
        return unless $name eq 'index.json' || $name eq 'status.json';
        my $record = JSON::PP->new->decode(read_file($path));
        my ($author, $distribution) =
            @{$record}{qw(author distribution)};
        if ($name eq 'index.json') {
            ($author) = map { author_from_path($_->{cpan_path}) }
                        @{$record->{releases}};
            is($record->{schema}, 1, "index schema: $path");
            for my $release (@{$record->{releases}}) {
                is(author_from_path($release->{cpan_path}), $author,
                   "release author: $path");
                for my $set (@{$release->{patch_sets}}) {
                    for my $patch (@{$set->{patches}}) {
                        my $file = File::Spec->catfile(dirname($path),
                            split m{/}, $patch->{path});
                        is(sha256_hex(read_file($file)), $patch->{sha256},
                           "patch digest: $file");
                    }
                }
            }
            ++$indexes;
        }
        else {
            is($record->{schema}, 2, "status schema: $path");
            for my $observation (@{$record->{observations}}) {
                is(author_from_path($observation->{cpan_path}), $author,
                   "observation author: $path");
            }
            ++$statuses;
        }
        my $prefix = unpack 'H2',
            siphash_2_4("$author/$distribution", "\0" x 16);
        my $expected = File::Spec->catfile($data_dir, $prefix, $author,
                                           $distribution, $name);
        is($path, $expected, "placement: $path");
    },
}, $data_dir);

ok($indexes > 0, 'patch indexes were found');
ok($statuses > 0, 'status records were found');
for my $summary (qw(SUMMARY.md UNRESOLVED.md)) {
    my $path = File::Spec->catfile($root, 'status', $summary);
    my $text = read_file($path);
    while ($text =~ m{\]\((\.\./data/[^)]+/status\.json)\)}g) {
        ok(-f File::Spec->catfile(dirname($path), split m{/}, $1),
           "summary link: $1");
    }
}

done_testing();

sub read_file {
    my ($path) = @_;
    open my $file, '<:raw', $path or die "$path: $!";
    local $/;
    return <$file>;
}

sub author_from_path {
    my ($path) = @_;
    my ($author) = $path =~ m{\A[A-Z]/[A-Z]{2}/([A-Z0-9_-]+)/[^/]+\z};
    die "invalid CPAN path: $path" unless defined $author;
    return $author;
}
