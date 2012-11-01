package WWW::Shutterstock::Lightbox;

# ABSTRACT: Representation of lightbox in Shutterstock's public API

use strict;
use version;
use Moo;
use WWW::Shutterstock::Image;
use WWW::Shutterstock::DeferredData qw(deferred);

with 'WWW::Shutterstock::AuthedClient';

deferred(
	['lightbox_name' => 'name', 'rw'],
	['images' => '_images', 'ro'],
	sub {
		my $self = shift;
		my $client = $self->client;
		$client->GET( sprintf('/lightboxes/%s/extended.json', $self->id), $self->with_auth_params );
		return $client->process_response;
	}
);

has id => ( is => 'rw', init_arg => 'lightbox_id' );
has public_url => ( is => 'lazy' );

sub _build_public_url {
	my $self = shift;
	my $client = $self->client;
	$client->GET( sprintf( '/lightboxes/%s/public_url.json', $self->id ), $self->with_auth_params );
	if(my $data = $client->process_response){
		return $data->{public_url};
	}
	return;
}

sub delete_image {
	my $self = shift;
	my $image_id = shift;
	my $client = $self->client;
	$client->DELETE(
		sprintf( '/lightboxes/%s/images/%s.json', $self->id, $image_id ),
		$self->with_auth_params( username => $self->username )
	);
	return $client->process_response;
}

sub add_image {
	my $self = shift;
	my $image_id = shift;
	my $client = $self->client;
	$client->PUT(
		sprintf(
			'/lightboxes/%s/images/%s.json?%s',
			$self->id,
			$image_id,
			$client->buildQuery(
				username   => $self->username,
				auth_token => $self->auth_token
			)
		)
	);
	return $client->process_response;
}

sub images {
	my $self = shift;
	return [ map { $self->new_with_auth('WWW::Shutterstock::Image', %$_ ) } @{ $self->_images || [] } ];
}

1;
