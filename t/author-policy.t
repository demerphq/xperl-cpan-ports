use strict;
use warnings;
use builtin qw(siphash_2_4);
no warnings 'experimental::builtin';
use File::Find qw(find);
use File::Spec;
use FindBin;
use JSON::PP;
use Test::More;

my $root = File::Spec->catdir($FindBin::Bin, '..');
my (%policy, $authors, $queued);

find({ no_chdir => 1, wanted => sub {
    my $path = $File::Find::name;
    return unless -f $path && $path =~ /\.json\z/;
    my $record = read_json($path);
    my $author = $record->{author};
    my $expected = substr($author, 0, 1) . '/'
                 . substr($author, 0, 2) . "/$author";
    like($path, qr{\Q$expected\E\.json\z}, "author placement: $path");
    is($record->{schema}, 1, "author schema: $path");
    like($record->{xperl_patches}{status}, qr/\A(?:accepting|declined)\z/,
         "author policy: $path");
    like($record->{xperl_patches}{confirmed_at}, qr/\A\d{4}-\d{2}-\d{2}\z/,
         "confirmation date: $path");
    $policy{$author} = $record->{xperl_patches}{status};
    ++$authors;
} }, File::Spec->catdir($root, 'authors'));

find({ no_chdir => 1, wanted => sub {
    my $path = $File::Find::name;
    return unless -f $path && $path =~ /\.json\z/;
    my $entry = read_json($path);
    my $author = $entry->{author};
    my $fanout = substr($author, 0, 1) . '/'
               . substr($author, 0, 2) . "/$author";
    like($path, qr{upstream-queue/\Q$fanout\E/[^/]+\.json\z},
         "queue placement: $path");
    is($entry->{schema}, 1, "queue schema: $path");
    is($policy{$author}, 'accepting', "author accepts patches: $path");
    my $prefix = unpack 'H2', siphash_2_4(
        "$author/$entry->{distribution}", "\0" x 16);
    my $index_path = File::Spec->catfile($root, 'data', $prefix,
        $author, $entry->{distribution}, 'index.json');
    ok(-f $index_path, "indexed distribution: $path") or return;
    my $index = read_json($index_path);
    my ($release) = grep {
        $_->{version} eq $entry->{version}
            && $_->{cpan_path} eq $entry->{cpan_path}
            && $_->{source_sha256} eq $entry->{source_sha256}
    } @{$index->{releases}};
    ok($release, "exact release: $path") or return;
    my ($set) = grep { $_->{id} eq $entry->{patch_set} }
                @{$release->{patch_sets}};
    ok($set, "patch set: $path") or return;
    ok((grep { $_->{sha256} eq $entry->{patch_sha256} }
         @{$set->{patches}}), "patch digest: $path");
    like($entry->{state}, qr/\A(?:ready|submitted|merged|declined)\z/,
         "queue state: $path");
    ++$queued;
} }, File::Spec->catdir($root, 'upstream-queue'));

ok($authors > 0, 'author policies found');
ok($queued > 0, 'upstream queue entries found');
done_testing();

sub read_json {
    my ($path) = @_;
    open my $file, '<:raw', $path or die "$path: $!";
    return JSON::PP->new->decode(do { local $/; <$file> });
}
