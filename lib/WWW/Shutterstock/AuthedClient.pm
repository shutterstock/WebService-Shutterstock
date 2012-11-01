package WWW::Shutterstock::AuthedClient;

use strict;
use warnings;
use Moo::Role;

with 'WWW::Shutterstock::HasClient';

has auth_info => ( is => 'ro', required => 1 );

sub new_with_auth {
	my $self = shift;
	my $class = shift;
	return $self->new_with_client( $class, @_, auth_info => $self->auth_info );
}

sub auth_token { return shift->auth_info->{auth_token} }
sub username   { return shift->auth_info->{username} }

sub with_auth_params {
	my $self = shift;
	my %other = @_;
	return { %other, auth_token => $self->auth_token };
}

1;
