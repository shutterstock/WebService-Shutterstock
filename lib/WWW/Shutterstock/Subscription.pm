package WWW::Shutterstock::Subscription;

use strict;
use warnings;
use Moo;
use JSON qw(encode_json);
use WWW::Shutterstock::LicensedImage;

with 'WWW::Shutterstock::AuthedClient';

has id => ( is => 'ro', init_arg => 'subscription_id' );
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

sub license_image {
	my $self     = shift;
	my $image_id = shift;
	my $size     = shift;
	my $metadata = shift || {};
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

sub is_active {
	my $self = shift;
	return $self->unix_expiration_time > time;
}

sub is_expired {
	return !shift->is_active;
}

1;
