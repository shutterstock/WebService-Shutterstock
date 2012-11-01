package WWW::Shutterstock::Image;

use strict;
use warnings;

use Moo;
use WWW::Shutterstock::DeferredData qw(deferred);

with 'WWW::Shutterstock::HasClient';

has id => ( is => 'ro', required => 1, init_arg => 'image_id' );

deferred(
	qw(
	  categories
		description
	  enhanced_license_available
	  illustration
		is_available
	  is_vector
	  keywords
	  model_release
	  r_rated
	  sizes
	  submitter
	  submitter_id
	  vector_type
	  web_url
	),
	sub {
		my $self   = shift;
		my $client = $self->client;
		$client->GET( sprintf( '/images/%s.json', $self->id ) );
		my $data = $client->process_response(404 => sub {
			return { is_available => 0 };
		});
		$data->{is_available} = 1 if ! exists $data->{is_available};
		return $data;
	}
);

sub size {
	my $self = shift;
	my $size = shift;
	return exists($self->sizes->{$size}) ? $self->sizes->{$size} : undef;
}

sub similar {
	my $self = shift;
	my $client = $self->client;
	$client->GET(sprintf('/images/%s/similar.json', $self->id));
	my $images = $client->process_response;
	return [ map { $self->new_with_auth( 'WWW::Shutterstock::Image', %$_ ) } @$images ];
}

1;
