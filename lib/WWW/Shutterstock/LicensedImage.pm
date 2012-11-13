package WWW::Shutterstock::LicensedImage;

# ABSTRACT: Allows for interogating and saving a licensed image from the Shutterstock API

use strict;
use warnings;
use Moo;
use LWP::Simple;
use WWW::Shutterstock::Exception;

my @attrs = qw(photo_id thumb_large_url allotment_charge download_url);
foreach my $attr(@attrs){
	has $attr => (is => 'ro');
}

=attr photo_id

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

Downloads a licensed image.  If no arguments are specified, the raw bytes
of the file are returned.  You can also specify a file OR a directory
(one or the other) to save the file instead of returning the raw bytes
(as demonstrated in the SYNOPSIS).

If a C<directory> or C<file> option is given, the path to the saved file
is returned.

B<WARNING:> files will be silently overwritten if an existing file of
the same name already exists.

=cut

sub download {
	my $self = shift;
	my %args = @_;

	my $url = $self->download_url;
	my $destination;
	if($args{directory}){
		$destination = $args{directory};
		$destination =~ s{/$}{};
		my($basename) = $url =~ m{.+/(.+)};
		$destination .= "/$basename";
	} elsif($args{file}){
		$destination = $args{file};
	}

	my $ua = LWP::UserAgent->new;
	my $response = $ua->get( $url, ( $destination ? ( ':content_file' => $destination ) : () ) );
	if(my $died = $response->header('X-Died') ){
		die WWW::Shutterstock::Exception->new(
			response => $response,
			error    => "Unable to save image to $destination: $died"
		);
	} elsif($response->code == 200){
		return $destination || $response->content;
	} else {
		die WWW::Shutterstock::Exception->new(
			response => $response,
			error    => $response->status_line . ": unable to retrieve image",
		);
	}
}

1;

=head1 SYNOPSIS

	my $licensed_image = $subscription->license_image(image_id => 59915404, size => 'medium');

	# retrieve the bytes of the file
	my $jpg_bytes = $licensed_image->download;

	# or, save the file to a valid filename
	$licensed_image->download(file => '/my/photos/my-pic.jpg');

	# or, specify the directory and the filename will reflect what the server specifies
	# (typically as something like shutterstock_59915404.jpg)
	my $path_to_file = $licensed_image->download(directory => '/my/photos');

=cut
