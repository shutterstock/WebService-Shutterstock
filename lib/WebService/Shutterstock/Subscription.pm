package WebService::Shutterstock::Subscription;

# ABSTRACT: Class representing a subscription for a specific Shutterstock customer

use strict;
use warnings;
use Moo;
use JSON qw(encode_json);
use WebService::Shutterstock::LicensedImage;
use Carp qw(croak);

with 'WebService::Shutterstock::AuthedClient';

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

=method sizes_for_licensing

Returns a list of sizes that can be specified when licensing an image
(see L<WebService::Shutterstock::Customer/license_image>).

=cut

sub sizes_for_licensing {
	my $self = shift;
	return
	  map  { $_->{name} }
	  grep { $_->{name} ne 'supersize' && $_->{format} ne 'tiff' }
	  values %{ $self->sizes || {} };
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
