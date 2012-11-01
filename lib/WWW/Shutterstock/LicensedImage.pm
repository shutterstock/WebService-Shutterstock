package WWW::Shutterstock::LicensedImage;

use strict;
use warnings;
use Moo;
use LWP::Simple qw(getstore);

my @attrs = qw(photo_id thumb_large allotment_charge download_url);
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
	return getstore($url, $destination);
}

1;
