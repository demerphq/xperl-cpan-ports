use strict;
use warnings;
use File::Find qw(find);
use File::Spec;
use FindBin;
use Test::More;

# Registry patches must be well-formed unified diffs. GNU patch tolerates
# hunks whose bodies do not match their headers, but other patch programs
# (BSD and macOS patch, git apply) reject them, so a malformed patch only
# applies on some platforms.

my $data = File::Spec->catdir($FindBin::Bin, '..', 'data');
my @patches;
find({
    no_chdir => 1,
    wanted => sub {
        push @patches, $File::Find::name
            if -f $File::Find::name && $File::Find::name =~ m{/patches/[^/]+\.patch\z};
    },
}, $data);
@patches = sort @patches;
ok(scalar @patches, 'registry has patches to check');

for my $path (@patches) {
    (my $name = $path) =~ s{\A\Q$data\E/}{};
    my @problems = check_patch($path);
    ok(!@problems, "$name is a well-formed unified diff")
        or diag join "\n", @problems;
}

done_testing();

sub check_patch {
    my ($path) = @_;
    open my $input, '<', $path or return "cannot read: $!";
    my @lines = <$input>;
    my @problems;
    my $files = 0;
    my $index = 0;
    while ($index < @lines) {
        my $line = $lines[$index];
        if ($line =~ /^--- / && ($lines[$index + 1] // '') =~ /^\+\+\+ /) {
            ++$files;
            $index += 2;
            next;
        }
        if (my ($old, $new) = $line =~ /^@@ -\d+(?:,(\d+))? \+\d+(?:,(\d+))? @@/) {
            my $hunk_line = $index + 1;
            $old //= 1;
            $new //= 1;
            ++$index;
            my ($seen_old, $seen_new) = (0, 0);
            while ($index < @lines && ($seen_old < $old || $seen_new < $new)) {
                my $body = $lines[$index];
                if    ($body =~ /^ / || $body eq "\n") { ++$seen_old; ++$seen_new }
                elsif ($body =~ /^-/)                  { ++$seen_old }
                elsif ($body =~ /^\+/)                 { ++$seen_new }
                elsif ($body =~ /^\\ /)                { }
                else                                   { last }
                ++$index;
            }
            ++$index while $index < @lines && $lines[$index] =~ /^\\ /;
            push @problems, "hunk at line $hunk_line declares $old old and $new new"
                . " lines but has $seen_old and $seen_new"
                if $seen_old != $old || $seen_new != $new;
            next;
        }
        push @problems, 'unexpected line ' . ($index + 1) . ": $line"
            if $line =~ /^[-+ @]/;
        ++$index;
    }
    push @problems, 'no file headers' unless $files;
    return @problems;
}
