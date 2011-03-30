use Modern::Perl;
use Test::More      tests => 1;

use Wiki::Basil;

my $basil = Wiki::Basil->new(
        source    => 't/source/',
        templates => 't/templates',
    );

my $expected = <<HTML;
<!DOCTYPE html>
<html>
<head>
  <title>Wiki page</title>
</head>
<body>
<h1>Test</h1>

<p>Test page.</p>

<p><a href='?action=edit'>Edit this page</a></p>
</body>
</html>
HTML

my $rendered = $basil->render_wiki_page( '/test' );
ok( $expected eq $rendered )
    or print $rendered;
