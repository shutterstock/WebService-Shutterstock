package WebService::Shutterstock::Video;

# ABSTRACT: Represent the set of information about a Shutterstock video as returned by the API

use strict;
use warnings;

use Moo;
use WebService::Shutterstock::DeferredData qw(deferred);

with 'WebService::Shutterstock::HasClient';

=attr id

The ID of this video on the Shutterstock system

=cut

has id => ( is => 'ro', required => 1, init_arg => 'video_id' );

deferred(
	qw(
		categories
		description
		keywords
		aspect_ratio_common
		aspect
		duration
		sizes
		model_release
		r_rated
		submitter_id
		web_url
		is_available
	),
	sub {
		my $self   = shift;
		my $client = $self->client;
		$client->GET( sprintf( '/videos/%s.json', $self->id ) );
		my $data = $client->process_response(404 => sub {
			return { is_available => 0 };
		});
		$data->{is_available} = 1 if $data->{video_id} && $self->id == $data->{video_id};
		return $data;
	}
);

sub size {
	my $self = shift;
	my $size = shift;
	return exists($self->sizes->{$size}) ? $self->sizes->{$size} : undef;
}

1;

=head1 SYNOPSIS

	my $video = $shutterstock->video(12345);
	printf(
		"Video %d (%dx%d) - %s\n",
		$video->id,
		$video->size('sd_original')->{width},
		$video->size('sd_original')->{height},
		$video->description
	);
	print "Categories:\n";
	foreach my $category ( @{ $video->categories } ) {
		printf( " - %s (%d)\n", $category->{category}, $category->{category_id} );
	}

=head1 DESCRIPTION

This module serves as a proxy class for the data returned from a URL
like L<http://api.shutterstock.com/videos/12345.json>.  Please look
at that data structure for a better idea of exactly what each of the attributes
in this class contains.

=method is_available

Boolean

=attr categories

ArrayRef of category names and IDs.

=attr description

=attr keywords

ArrayRef of keywords describing this video

=attr aspect_ratio_common

The aspect ratio in string form (i.e "4:3")

=attr aspect

The aspect ratio of this video in decimal form (i.e. 1.3333)

=attr duration

Length of the video in seconds

=attr r_rated

Boolean

=attr sizes

Returns a HashRef of information about the various sizes for the image.

=method size

Returns details for a specific size.  Some sizes provide dimensions,
format, FPS and file size (lowres_mpeg, sd_mpeg, sd_original). Other sizes
provide a URL for a video or still preview (thumb_video, preview_video,
preview_image).

=attr model_release

=attr submitter_id

ID of the submitter who uploaded the video to Shutterstock.

=attr web_url

A URL for the main page on Shutterstock's site for this video.

=cut
