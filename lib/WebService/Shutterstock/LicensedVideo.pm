package WebService::Shutterstock::LicensedVideo;

# ABSTRACT: Allows for interogating and saving a licensed video from the Shutterstock API

use strict;
use warnings;
use Moo;

with 'WebService::Shutterstock::LicensedMedia';

my @attrs = qw(video_id thumb_large_url allotment_charge);
foreach my $attr(@attrs){
	has $attr => (is => 'ro');
}

=attr video_id

=attr thumb_large_url

=attr allotment_charge

=attr download_url

=cut

sub BUILDARGS {
	my $args = shift->SUPER::BUILDARGS(@_);
	$args->{download_url} = $args->{download}->{url};
	$args->{thumb_large_url} = $args->{thumb_large}->{url};
	return $args;
}

=for Pod::Coverage BUILDARGS

=method download

Downloads a licensed video.  If no arguments are specified, the raw bytes
of the file are returned.  You can also specify a file OR a directory
(one or the other) to save the file instead of returning the raw bytes
(as demonstrated in the SYNOPSIS).

If a C<directory> or C<file> option is given, the path to the saved file
is returned.

B<WARNING:> files will be silently overwritten if an existing file of
the same name already exists.

=cut

1;

=head1 SYNOPSIS

	my $licensed_video = $subscription->license_video(video_id => 11234, size => 'lowres');

	# retrieve the bytes of the file
	my $jpg_bytes = $licensed_video->download;

	# or, save the file to a valid filename
	$licensed_video->download(file => '/my/videos/my-video.mpg');

	# or, specify the directory and the filename will reflect what the server specifies
	# (typically as something like shutterstock_11234.mpg)
	my $path_to_file = $licensed_video->download(directory => '/my/videos');

=cut
