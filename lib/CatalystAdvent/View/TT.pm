package CatalystAdvent::View::TT;

use strict;
use warnings;

use base qw( Catalyst::View::TT );

__PACKAGE__->config( {
    WRAPPER => 'wrapper.tt'
} );

=head1 NAME

CatalystAdvent::View::TT - Catalyst TT View

=head1 SYNOPSIS

See L<CatalystAdvent>

=head1 DESCRIPTION

Catalyst TT View.

=head1 AUTHORS

Brian Cassidy, <bricas@cpan.org>

Sebastian Riedel, <sri@cpan.org>

Andy Grundman, <andy@hybridized.org>

Marcus Ramberg, <mramberg@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
