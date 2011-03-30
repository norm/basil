use Modern::Perl;
use Data::Dumper;
use Test::More      tests => 1;

use Wiki::Basil;


my $basil = Wiki::Basil->new(
        source    => 't/source',
        templates => 't/templates',
    );

my @expected = (
        '/page',
        '/test',
    );
my @pages = $basil->list_pages();
is_deeply( \@pages, \@expected )
    or print Dumper @pages;
