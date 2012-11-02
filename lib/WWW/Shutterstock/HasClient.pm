package WWW::Shutterstock::HasClient;

# ABSTRACT: Role managing a client attribute

use strict;
use warnings;
use Moo::Role;

has client => ( is => 'ro', required => 1 );

=method new_with_client

=cut

sub new_with_client {
	my $self = shift;
	my $class = shift;
	return $class->new( client => $self->client, @_ );
}

1;

=head1 DESCRIPTION

This role serves a similar purpose as L<WWW::Shutterstock::AuthedClient>
by providing a simple way to create a new object with the C<client>
object managed by this role.

You should not need to use this role in order to use L<WWW::Shutterstock>.

=cut
