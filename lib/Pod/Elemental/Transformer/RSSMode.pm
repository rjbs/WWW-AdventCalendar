package Pod::Elemental::Transformer::RSSMode;

use Moose;
with 'Pod::Elemental::Transformer';
 
use namespace::autoclean;
 
## TODO: This should work with =begin as well as =for, but doesn't yet!
## TODO: probably should work inside containers, but doesn't (oops)

has web_mode => (
    is => 'ro',
    default => 0,
);

has _to_be_removed_regex => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_to_be_removed_regex',
);

sub _build_to_be_removed_regex {
    my $self = shift;
    return qr/\Aweb_only/ if $self->web_mode;
    return qr/\Arss_only/;
}

sub transform_node {
    my ($self, $node) = @_;

    # remove the =for web_only or =for rss_only that don't apply
    $self->_remove_nodes($node);

    # turn the =for web_only or =for rss_only into =for html
    $self->_rename_nodes($node);
}

sub _rename_nodes {
    my $self = shift;
    my $node = shift;

    foreach (@{ $node->children }) {
        next unless $_->can('command') && $_->command eq 'for';

        my $content = $_->content;
        $content =~ s/\Aweb_only/html/;
        $content =~ s/\Arss_only/html/;
        $_->content( $content );
    }
}

sub _remove_nodes {
    my $self = shift;
    my $node = shift;

    $node->children([
        grep { !(
            $_->can('command')
                 && $_->command eq 'for'
                 && $_->content =~ $self->_to_be_removed_regex
        ) } @{ $node->children }
    ]);
}

__PACKAGE__->meta->make_immutable;
1;

