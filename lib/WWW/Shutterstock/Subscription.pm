package WWW::Shutterstock::Subscription;

# ABSTRACT: Class representing a subscription for a specific Shutterstock customer

use strict;
use warnings;
use Moo;
use JSON qw(encode_json);
use WWW::Shutterstock::LicensedImage;
use Carp qw(croak);

with 'WWW::Shutterstock::AuthedClient';

=attr id

=attr unix_expiration_time

=attr current_allotment

=attr description

=attr license

=attr sizes

=attr site

=attr expiration_time

=cut

has id => ( is => 'ro', required => 1, init_arg => 'subscription_id' );
my @fields = qw(
	  unix_expiration_time
	  current_allotment
	  description
	  license
	  sizes
	  site
	  expiration_time
);
foreach my $f(@fields){
	has $f => ( is => 'ro' );
}

=method license_image( image_id => $id, size => $size )

Licenses a specific image in the requested size.  Returns a L<WWW::Shutterstock::LicensedImage> object.

=cut

sub license_image {
	my $self     = shift;
	my %args     = @_;
	my $image_id = $args{image_id} or croak "Must specify image_id to license";
	my $size     = $args{size} or croak "Must specify size of image to license";
	my $metadata = $args{metadata} || {purchase_order => '', job => '', client => '', other => ''};

	my @valid_sizes =
	  map { $_->{name} }
	  grep { $_->{name} ne 'supersize' && $_->{format} ne 'tiff' }
	  values %{ $self->sizes || {} };
	if ( @valid_sizes && !grep { $_ eq $size } @valid_sizes ) {
		croak "invalid size '$size' (valid options: "
		  . ( join ", ", sort @valid_sizes ) . ")";
	}

	my $format   = $size eq 'vector' ? 'eps' : 'jpg';
	my $client   = $self->client;
	$client->POST(
		sprintf(
			'/subscriptions/%s/images/%s/sizes/%s.json',
			$self->id, $image_id, $size
		),
		$self->with_auth_params(
			format   => $format,
			metadata => encode_json($metadata),
		)
	);
	return WWW::Shutterstock::LicensedImage->new($client->process_response);
}

=method is_active

Convenience method returning a boolean value indicating whether the subscription is active (e.g. has not expired).

=cut

sub is_active {
	my $self = shift;
	return $self->unix_expiration_time > time;
}

=method is_expired

Convenience method returning a boolean value indicating whether the subscription has expired.

=cut

sub is_expired {
	return !shift->is_active;
}

1;
