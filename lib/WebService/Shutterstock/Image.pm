package WebService::Shutterstock::Image;

# ABSTRACT: Represent the set of information about a Shutterstock image as returned by the API

use strict;
use warnings;

use Moo;
use WebService::Shutterstock::DeferredData qw(deferred);

use WebService::Shutterstock::HasClient;
with 'WebService::Shutterstock::HasClient';

=attr id

The ID of this image on the Shutterstock system

=cut

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
	return [ map { $self->new_with_client( 'WebService::Shutterstock::Image', %$_ ) } @$images ];
}

1;

=head1 SYNOPSIS

	my $image = $shutterstock->image(59915404);
	printf(
		"Image %d (%dx%d) - %s\n",
		$image->id,
		$image->size('huge')->{width},
		$image->size('huge')->{height},
		$image->description
	);
	print "Categories:\n";
	foreach my $category ( @{ $image->categories } ) {
		printf( " - %s (%d)\n", $category->{category}, $category->{category_id} );
	}

=head1 DESCRIPTION

This module serves as a proxy class for the data returned from a URL
like L<http://api.shutterstock.com/images/15484942.json>.  Please look
at that data structure for a better idea of exactly what each of the attributes
in this class contains.

=attr categories

ArrayRef of category names and IDs.

=attr description

=attr enhanced_license_available

Boolean

=attr illustration

Boolean

=attr is_vector

Boolean

=attr keywords

ArrayRef of keywords.

=attr model_release

Details regarding

=attr r_rated

Boolean

=method similar

Returns an ArrayRef of L<WebService::Shutterstock::Image> objects similar to
the current image.

=attr sizes

Returns a HashRef of information about the various sizes for the image.

=method size

Returns details for a specific size.  Some sizes provide just dimensions
(small, medium, large). Other sizes include a URL for the image as well
(thumb_small, thumb_large).

=attr submitter

Name of the individual who submitted the image to Shutterstock.

=attr submitter_id

ID of the submitter.

=attr vector_type

For a JPG image, this is C<undef>.  For a vector image, this would be a value like C<"eps">.

=attr web_url

A URL for the main page on Shutterstock's site for this image.

=cut

