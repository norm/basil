package Wiki::Basil;

use Modern::Perl;

use IO::All             -utf8;
use Template::Jigsaw;
use Text::Markdown      qw( markdown );



sub new {
    my $class = shift;
    my %args  = @_;
    
    my $self = {};
    bless $self, $class;
    
    $self->{'source'}    = delete $args{'source'}    // 'source';
    $self->{'templates'} = delete $args{'templates'} // 'templates';
    
    $self->{'jigsaw'} = Template::Jigsaw->new( $self->{'templates'} );
    
    return $self;
}

sub render_wiki_page {
    my $self = shift;
    my $page = shift;
    
    my $content = $self->get_wiki_source( $page );
    
    my ( $output, $errors ) = $self->jigsaw->render(
            $page,
            'html',
            {
                action => 'view',
            },
            {
                content => $content,
            }
        );
    
    return $output;
}
sub get_wiki_source {
    my $self = shift;
    my $page = shift;
    
    my $file = sprintf "%s%s.markdown",
                   $self->{'source'},
                   $page,
                   ".markdown";
    
    my $io = io $file;
    my $content;
    
    if ( $io->exists && $io->is_file ) {
        my $wiki_links = qr{
                ^
                    (.*?)                   # $1: before the link
                    \[ \[ \s*
                      ( [^\]\|]+? )         # $2: the text of the link
                      (?:
                          \s* \| \s*
                          (.*?)             # $3: (optional) link URL
                      )?
                    \s* \] \]
            }sx;
        
        $content = $io->all;
        my $output;
        
        while ( $content =~ s{$wiki_links}{}sx ) {
            my $before = $1;
            my $text   = $2;
            my $url    = $3 // $text;

            if ( $url =~ m{\s} ) {
                $url =~ tr/A-Z/a-z/;
                $url =~ s{\s+}{-}gs;
            }
            
            $output .= $before;
            $output .= "[${text}](${url})";
        }
        $output .= $content;
        
        $content = markdown $output;
    }
    
    return $content;
}

sub jigsaw {
    my $self = shift;
    return $self->{'jigsaw'};
}

1;
