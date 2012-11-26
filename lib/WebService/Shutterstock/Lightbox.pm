package WebService::Shutterstock::Lightbox;

# ABSTRACT: Representation of a lightbox in Shutterstock's public API

use strict;
use version;
use Moo;
use WebService::Shutterstock::Image;
use WebService::Shutterstock::DeferredData qw(deferred);

with 'WebService::Shutterstock::AuthedClient';

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

=attr id

The ID of this lightbox

=attr name

The name of this lightbox

=attr public_url

Returns a URL for access this lightbox without authenticating.

=cut

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

=method delete_image

Removes an image from this lightbox.

=cut

sub delete_image {
	my $self = shift;
	my $image_id = shift;
	my $client = $self->client;
	$client->DELETE(
		sprintf( '/lightboxes/%s/images/%s.json', $self->id, $image_id ),
		$self->with_auth_params( username => $self->username )
	);
	delete $self->{_images};
	return $client->process_response;
}

=method add_image($id)

Adds an image to this lightbox.

=cut

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
	delete $self->{_images};
	return $client->process_response;
}

=attr images

Returns a list of L<WebService::Shutterstock::Image> objects that are in this lightbox.

=cut

sub images {
	my $self = shift;
	return [ map { $self->new_with_auth('WebService::Shutterstock::Image', %$_ ) } @{ $self->_images || [] } ];
}

1;
