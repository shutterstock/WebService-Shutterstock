package WebService::Shutterstock::SearchResult::Video;

# ABSTRACT: Class representing a single video search result from the Shutterstock API

use strict;
use warnings;
use Moo;

use WebService::Shutterstock::HasClient;
use WebService::Shutterstock::SearchResult::Item;

with 'WebService::Shutterstock::HasClient', 'WebService::Shutterstock::SearchResult::Item';

=attr video_id

The video ID for this search result.

=attr thumb_video

A HashRef containing a webm and mp4 URL for a "thumbnail" size of this video.

=attr preview_video

A HashRef containing a webm and mp4 URL for a "preview" size of this video.

=attr preview_image_url

An URL for a watermarked preview of this image. 

=attr web_url

The L<http://footage.shutterstock.com> link for this image.

=attr description

An abbreviated description of this search result.

=attr submitter_id

The ID for the submitter of this video.

=attr duration

Length of this video in seconds.

=attr aspect_ratio_common

Aspect ratio as a string (i.e. "16:9").

=attr aspect

Aspect ratio as a float (i.e. 1.7778).

=cut

=for Pod::Coverage BUILDARGS

=cut

sub BUILDARGS {
	my $class = shift;
	my $args = $class->SUPER::BUILDARGS(@_);
	$args->{thumb_video} ||= $args->{sizes}->{thumb_video};
	$args->{preview_video} ||= $args->{sizes}->{preview_video};
	$args->{preview_image_url} ||= $args->{sizes}->{preview_image}->{url};
	return $args;
}

has video_id => ( is => 'ro' ); # sic, should be image_id to be consistant I think

has thumb_video => ( is => 'ro' );
has preview_video => ( is => 'ro' );
has preview_image_url => ( is => 'ro' );

has submitter_id => ( is => 'ro' );
has duration => ( is => 'ro' );
has aspect_ratio_common => ( is => 'ro' );
has aspect => ( is => 'ro' );

=method video

Returns a L<WebService::Shutterstock::Video> object for this search result.

=cut

sub video {
	my $self = shift;
	return $self->new_with_client( 'WebService::Shutterstock::Video', %$self );
}

1;

=head1 SYNOPSIS

	my $search = $shutterstock->search_video(searchterm => 'butterfly');
	my $results = $search->results;
	foreach my $result(@$results){
		printf "%d: %s\n", $result->video_id, $result->description;
		print "Tags: ";
		print join ", ", @{ $result->video->keywords };
		print "\n";
	}

=head1 DESCRIPTION

An object of this class provides information about a single search result.  When executing a search, an array
of these objects is returned by the L<WebService::Shutterstock::SearchResults/"results"> method.

=cut
