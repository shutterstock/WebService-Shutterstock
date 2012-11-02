package WWW::Shutterstock::AuthedClient;

# ABSTRACT: Role comprising a REST client with the necessary auth token information

use strict;
use warnings;
use Moo::Role;

with 'WWW::Shutterstock::HasClient';

=attr auth_info

HashRef of C<auth_token> and C<username>.

=cut

has auth_info => ( is => 'ro', required => 1 );

=head1 DESCRIPTION

This role provides convenience methods for managing an authenticated
client.  It consumes the L<WWW::Shutterstock::HasClient> role.

You should not need to use this role to use L<WWW::Shutterstock>

=cut

=method auth_token

Returns the token from the C<auth_info> hash.

=method username

Returns the username from the C<auth_info> hash.

=cut

sub auth_token { return shift->auth_info->{auth_token} }
sub username   { return shift->auth_info->{username} }

=method new_with_auth($some_class, attribute => 'value')

Returns an instance of the passed in class initialized with the arguments
passed in as well as the C<auth_info> and C<client> provided by this role

=cut

sub new_with_auth {
	my $self = shift;
	my $class = shift;
	return $self->new_with_client( $class, @_, auth_info => $self->auth_info );
}

=method with_auth_params(other => 'param')

Returns a HashRef of the passed-in params combined with the C<auth_token>.

=cut

sub with_auth_params {
	my $self = shift;
	my %other = @_;
	return { %other, auth_token => $self->auth_token };
}

1;
