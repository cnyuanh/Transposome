package Transposome;

use 5.010;
use Moose;
use YAML::Tiny;
use Log::Any qw($log);
use namespace::autoclean;

with 'Transposome::Role::Config';

=head1 NAME

Transposome - Investigate the repeat strucuture of a genome through unassembled sequence reads.

=head1 VERSION

Version 0.11.3

=cut

our $VERSION = '0.11.3';
#$VERSION = eval $VERSION;

=head1 SYNOPSIS

    transposome --config transposome_config.yml

=cut

has 'config' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 0,
    documentation => qq{The Transposome configuration file},
);

sub get_configuration {
    my $self = shift;
    my $configfile   = YAML::Tiny->read( $self->config );
    my $valid_config = $self->parse_configuration( $configfile );
    return $valid_config;
}

=head1 AUTHOR

S. Evan Staton, C<< <evan at evanstaton.com> >>

=head1 BUGS

Please report any bugs or feature requests through the project site at 
L<https://github.com/sestaton/Transposome/issues>. I will be notified,
and there will be a record of the issue. Alternatively, I can also be 
reached at the email address listed above to resolve any questions.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Transposome


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013-2017 S. Evan Staton

This program is distributed under the MIT (X11) License, which should be distributed with the package. 
If not, it can be found here: L<http://www.opensource.org/licenses/mit-license.php>

=cut

__PACKAGE__->meta->make_immutable;

1;
