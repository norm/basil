package Wiki::Basil;

use Modern::Perl;

use File::Basename;
use File::Path;
use HTML::Entities;
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
    my $self   = shift;
    my $page   = shift;
    my $action = shift // 'view';
    
    my $original = $self->get_wiki_source( $page );
    my $source   = $self->convert_wiki_links( $original );
    my $html     = markdown $source;
    
    $original = encode_entities( $original );
    
    my ( $output, $errors ) = $self->jigsaw->render(
            $page,
            'html',
            {
                action => $action,
            },
            {
                html     => $html,
                markdown => $original,
                page     => $page,
            }
        );
    
    return $output;
}
sub get_wiki_source {
    my $self = shift;
    my $page = shift;
    
    my $file = $self->page_to_filename( $page );
    my $io   = io $file;
    
    return $io->all
        if $io->exists && $io->is_file;
    return;
}
sub convert_wiki_links {
    my $self    = shift;
    my $content = shift;
    
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
    
    return $output;
}

sub update_wiki_page {
    my $self    = shift;
    my $page    = shift;
    my $content = shift;
    my $reason  = shift // "Update $page";
    
    $self->write_wiki_page( $page, $content )
        or return;
}
sub write_wiki_page {
    my $self    = shift;
    my $page    = shift;
    my $content = shift;
    
    my $file = $self->page_to_filename( $page );
    my $io   = io $file;
    
    my $dir = dirname $file;
    return if -f $dir;
    
    mkpath $dir;
    
    $io->print( $content )
        unless $io->exists && ! $io->is_file;
}

sub page_to_filename {
    my $self = shift;
    my $page = shift;
    
    $page .= "index"
        if '/' eq substr $page, -1, 1;
    
    return sprintf "%s%s.markdown",
                $self->{'source'},
                $page,
                ".markdown";
}

sub list_pages {
    my $self = shift;
    
    my @pages = $self->scan_directory( $self->{'source' } );
    return map {
            s{ \.markdown $}{}x;
            $_;
        } grep {
            m{ \.markdown $}x
        }
        @pages;
}
sub scan_directory {
    my $self      = shift;
    my $directory = shift;
    
    my $source = $self->{'source'};
    my @found = $self->traverse_directory( $directory );
    return map {
            s{^ $source }{}x;
            $_;
        } @found;
}
sub traverse_directory {
    my $self      = shift;
    my $directory = shift;
    
    my @files;
    opendir( my $handle, $directory );
    while ( my $entry = readdir $handle ) {
        next if '.' eq substr $entry, 0, 1;
        
        my $filename = "${directory}/${entry}";
        if ( -f $filename ) {
            push @files, $filename;
        }
        elsif ( -d $filename ) {
            push @files, $self->traverse_directory( $filename );
        }
    }
    
    return @files;
}

sub jigsaw {
    my $self = shift;
    return $self->{'jigsaw'};
}

1;
