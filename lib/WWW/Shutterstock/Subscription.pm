package WWW::Shutterstock::Subscription;
BEGIN {
  $WWW::Shutterstock::Subscription::AUTHORITY = 'cpan:BPHILLIPS';
}
{
  $WWW::Shutterstock::Subscription::VERSION = '0.001';
}

# ABSTRACT: Class representing a subscription for a specific Shutterstock customer

use strict;
use warnings;
use Moo;
use JSON qw(encode_json);
use WWW::Shutterstock::LicensedImage;
use Carp qw(croak);

with 'WWW::Shutterstock::AuthedClient';


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


sub is_active {
	my $self = shift;
	return $self->unix_expiration_time > time;
}


sub is_expired {
	return !shift->is_active;
}

1;

__END__

=pod

=head1 NAME

WWW::Shutterstock::Subscription - Class representing a subscription for a specific Shutterstock customer

=head1 VERSION

version 0.001

=head1 ATTRIBUTES

=head2 id

=head2 unix_expiration_time

=head2 current_allotment

=head2 description

=head2 license

=head2 sizes

=head2 site

=head2 expiration_time

=head1 METHODS

=head2 license_image( image_id => $id, size => $size )

Licenses a specific image in the requested size.  Returns a L<WWW::Shutterstock::LicensedImage> object.

=head2 is_active

Convenience method returning a boolean value indicating whether the subscription is active (e.g. has not expired).

=head2 is_expired

Convenience method returning a boolean value indicating whether the subscription has expired.

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
