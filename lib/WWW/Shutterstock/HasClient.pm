package WWW::Shutterstock::HasClient;

use strict;
use warnings;
use Moo::Role;

has client => ( is => 'ro', required => 1 );

sub new_with_client {
	my $self = shift;
	my $class = shift;
	return $class->new( client => $self->client, @_ );
}

1;
