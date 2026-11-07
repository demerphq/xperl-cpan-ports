use strict;
use warnings;

use File::Find qw(find);
use File::Spec;
use FindBin;
use JSON::PP;
use Test::More;

my $root = File::Spec->catdir($FindBin::Bin, '..', 'data');
my @paths;
find({
    no_chdir => 1,
    wanted => sub {
        push @paths, $File::Find::name
            if -f $File::Find::name
                && $File::Find::name =~ m{/evidence/[^/]+\.json\z};
    },
}, $root);

my $json = JSON::PP->new->canonical;
my %seen;
for my $path (sort @paths) {
    open my $input, '<:raw', $path or die "$path: $!";
    local $/;
    my $record = $json->decode(<$input>);

    # A different recording date alone does not add validation evidence.
    delete $record->{date};
    my $facts = $json->encode($record);
    ok(!exists($seen{$facts}), "distinct evidence: $path")
        or diag "same facts as $seen{$facts}";
    $seen{$facts} //= $path;
}

ok(@paths > 0, 'patch evidence records were found');
done_testing();
