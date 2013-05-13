package WebService::Shutterstock::LicensedMedia;

# ABSTRACT: Role for providing common functionality for licensed media

use strict;
use warnings;
use Moo::Role;
use Carp qw(croak);
use WebService::Shutterstock::Exception;
use LWP::UserAgent;

=attr download_url

=cut

has download_url => ( is => 'ro' );

=method download

Downloads media.  See examples and additional details in consumers of this role.

=cut

sub download {
	my $self = shift;
	my %args = @_;
	my @unknown_args = grep { !/^(file|directory)$/ } keys %args;

	croak "Invalid args: @unknown_args (expected either 'file' or 'download')" if @unknown_args;

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
	if(!defined $destination && !defined wantarray){
		croak "Refusing to download media in void context without specifying a destination file or directory (specify ->download(file => \$some_file) or ->download(directory => \$some_dir)"; 
	}
	my $ua = LWP::UserAgent->new;
	my $response = $ua->get( $url, ( $destination ? ( ':content_file' => $destination ) : () ) );
	if(my $died = $response->header('X-Died') ){
		die WebService::Shutterstock::Exception->new(
			response => $response,
			error    => "Unable to save media to $destination: $died"
		);
	} elsif($response->code == 200){
		return $destination || $response->content;
	} else {
		die WebService::Shutterstock::Exception->new(
			response => $response,
			error    => $response->status_line . ": unable to retrieve media",
		);
	}
}

1;
