package WWW::Shutterstock::Subscription;

# ABSTRACT: Class representing a subscription for a specific Shutterstock customer

use strict;
use warnings;
use Moo;
use JSON qw(encode_json);
use WWW::Shutterstock::LicensedImage;

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

=method license_image( $id, $size )

Licenses a specific image in the requested size.  Returns a L<WWW::Shutterstock::LicensedImage> object.

=cut

sub license_image {
	my $self     = shift;
	my $image_id = shift;
	my $size     = shift;
	my $metadata = shift || {purchase_order => '', job => '', client => '', other => ''};
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
