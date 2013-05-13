package WebService::Shutterstock::SearchResult::Image;

# ABSTRACT: Class representing a single image search result from the Shutterstock API

use strict;
use warnings;
use Moo;

use WebService::Shutterstock::HasClient;
use WebService::Shutterstock::SearchResult::Item;

with 'WebService::Shutterstock::HasClient', 'WebService::Shutterstock::SearchResult::Item';

=attr photo_id

The image ID for this search result.

=attr thumb_small

A HashRef containing a height, width and URL for a "small" thumbnail of this image. 

=attr thumb_large

A HashRef containing a height, width and URL for a "large" thumbnail of this image. 

=attr preview

A HashRef containing a height, width and URL for a watermarked preview of this image. 

=attr web_url

The L<http://www.shutterstock.com> link for this image.

=attr description

An abbreviated description of this search result.

=cut

has photo_id => ( is => 'ro' ); # sic, should be image_id to be consistant I think

has thumb_small => ( is => 'ro' );
has thumb_large => ( is => 'ro' );
has preview     => ( is => 'ro' );

=method image

Returns a L<WebService::Shutterstock::Image> object for this search result.

=cut

sub image {
	my $self = shift;
	return $self->new_with_client( 'WebService::Shutterstock::Image', image_id => $self->photo_id );
}

1;

=head1 SYNOPSIS

	my $search = $shutterstock->search(searchterm => 'butterfly');
	my $results = $search->results;
	foreach my $result(@$results){
		printf "%d: %s\n", $result->photo_id, $result->description;
		print "Tags: ";
		print join ", ", @{ $result->image->keywords };
		print "\n";
	}

=head1 DESCRIPTION

An object of this class provides information about a single search result.  When executing a search, an array
of these objects is returned by the L<WebService::Shutterstock::SearchResults/"results"> method.

=cut
