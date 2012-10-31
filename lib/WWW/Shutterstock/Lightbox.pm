package WWW::Shutterstock::Lightbox;

# ABSTRACT: Representation of lightbox in Shutterstock's public API

use strict;
use version;
use Moo;
use WWW::Shutterstock::Image;

has ss => ( is => 'rw', weak_ref => 1 );

has id => ( is => 'rw', init_arg => 'lightbox_id' );
has name => ( is => 'rw', init_arg => 'lightbox_name' );
has _images => ( is => 'rw', init_arg => 'images' );

sub delete_image {
	my $self = shift;
	my $image_id = shift;
	my $client = $self->ss->_client;
	$self->ss->require_auth;
	$client->DELETE(
		sprintf(
			'/lightboxes/%s/images/%s?%s',
			$self->id,
			$image_id,
			$client->buildQuery(
				username   => $self->ss->username,
				auth_token => $self->ss->auth_token
			)
		)
	);
}

sub add_image {
	my $self = shift;
	my $image_id = shift;
	my $client = $self->ss->_client;
	$self->ss->require_auth;
	$client->PUT(
		sprintf(
			'/lightboxes/%s/images/%s?%s',
			$self->id,
			$image_id,
			$client->buildQuery(
				username   => $self->ss->username,
				auth_token => $self->ss->auth_token
			)
		)
	);
}

sub images {
	my $self = shift;
	return [ map { WWW::Shutterstock::Image->new( %$_, ss => $self->ss ) } @{ $self->_images || [] } ];
}

1;
