package WWW::Shutterstock::LicensedImage;
BEGIN {
  $WWW::Shutterstock::LicensedImage::AUTHORITY = 'cpan:BPHILLIPS';
}
{
  $WWW::Shutterstock::LicensedImage::VERSION = '0.001';
}

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


sub BUILDARGS {
	my $args = shift->SUPER::BUILDARGS(@_);
	$args->{download_url} = $args->{download}->{url};
	$args->{thumb_large_url} = $args->{thumb_large}->{url};
	return $args;
}


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
	my $response = $ua->get($url, ':content_file' => $destination);
	if(my $died = $response->header('X-Died') ){
		die WWW::Shutterstock::Exception->new(
			response => $response,
			error    => "Unable to save image to $destination: $died"
		);
	} elsif($response->code == 200){
		return $destination;
	} else {
		die WWW::Shutterstock::Exception->new(
			response => $response,
			error    => $response->status_line . ": unable to retrieve image",
		);
	}
}

1;

__END__

=pod

=head1 NAME

WWW::Shutterstock::LicensedImage - Allows for interogating and saving a licensed image from the Shutterstock API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

	my $licensed_image = $subscription->license_image(123456789, 'medium');

	# saves the file to the /my/photos directory (typically as something like shutterstock_123456789.jpg)
	$licensed_image->save('/my/photos');

	# or specify the actual filename
	$licensed_image->save('/my/photos/my-pic.jpg');

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 photo_id

=head2 thumb_large_url

=head2 allotment_charge

=head2 download_url

=head1 METHODS

=head2 save($file_or_directory)

Saves a licensed image to a local file.  If a directory is specified
by the method argument, the image is saved in that directory using the
filename indicated by the server.  Otherwise, the file is saved to the
full path of the file indicated.

The path to the saved file is returned.

=for Pod::Coverage BUILDARGS

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
