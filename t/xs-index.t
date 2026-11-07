use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP;
use Test::More;

my $root = File::Spec->catdir($FindBin::Bin, '..');
my $script = File::Spec->catfile($root, 'bin', 'build-xs-index');
my $catalog_path = File::Spec->catfile($root, 'status', 'XS-PATCHES.json');

is(system($^X, $script, '--check'), 0,
   'native patch catalog matches the registered patches');

open my $input, '<:raw', $catalog_path or die "$catalog_path: $!";
local $/;
my $catalog = JSON::PP->new->decode(<$input>);
is($catalog->{schema}, 1, 'native patch catalog schema');

for my $entry (@{$catalog->{entries}}) {
    my $name = "$entry->{author}/$entry->{distribution} $entry->{version}";
    ok(@{$entry->{native_files}}, "$name lists a native source file");
    for my $key (qw(index_path patch_paths evidence_paths)) {
        my @paths = $key eq 'index_path'
            ? ($entry->{$key}) : @{$entry->{$key}};
        for my $path (@paths) {
            ok(-f File::Spec->catfile($root, split m{/}, $path),
               "$name links $path");
        }
    }
}

done_testing();
