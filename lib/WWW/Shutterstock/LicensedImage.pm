package WWW::Shutterstock::LicensedImage;

# ABSTRACT: Allows for interogating and saving a licensed image from the Shutterstock API

use strict;
use warnings;
use Moo;
use LWP::Simple;

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

=method save($file_or_directory)

Saves a licensed image to a local file.  If a directory is specified
by the method argument, the image is saved in that directory using the
filename indicated by the server.  Otherwise, the file is saved to the
full path of the file indicated.

The path to the saved file is returned.

=cut

sub save {
	my $self = shift;
	my $destination = shift;
	my $url = $self->download_url;
	if(-d $destination){
		$destination =~ s{/$}{};
		my($basename) = $url =~ m{.+/(.+)};
		$destination .= "/$basename";
	}
	my $ua = LWP::UserAgent->new;
	$DB::single=1;
	my $response = $ua->get($url, ':content_file' => $destination);
	if(my $died = $response->header('X-Died') ){
		die "Unable to save image to $destination: $died";
	} elsif($response->code == 200){
		return $destination;
	} else {
		die "Unable to retrieve image: " . $response->status_line;
	}
}

1;

=head1 SYNOPSIS

	my $licensed_image = $subscription->license_image(123456789, 'medium');

	# saves the file to the /my/photos directory (typically as something like shutterstock_123456789.jpg)
	$licensed_image->save('/my/photos');

	# or specify the actual filename
	$licensed_image->save('/my/photos/my-pic.jpg');

=head1 DESCRIPTION

=cut
