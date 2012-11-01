package WWW::Shutterstock;

# ABSTRACT: Easy access to Shutterstock's public API

use strict;
use warnings;

use Carp qw(croak);
use Moo 1;
use REST::Client;
use MIME::Base64;
use JSON qw(encode_json decode_json);
use WWW::Shutterstock::Lightbox;
use WWW::Shutterstock::Client;
use WWW::Shutterstock::Customer;
use WWW::Shutterstock::SearchResults;

has api_username => (
	is => 'ro',
	required => 1,
);
has api_key => (
	is => 'ro',
	required => 1,
);
has client_config => (
	is => 'ro',
	isa => sub { croak "client_config must be a HashRef" unless ref $_[0] eq 'HASH'; },
);

has client => (
	is       => 'lazy',
	clearer  => 1,
);

sub _build_client {
	my $self = shift;
	my $config = $self->client_config || {};
	my $client = WWW::Shutterstock::Client->new(
		host => 'http://api.shutterstock.com',
		%$config
	);
	$client->addHeader(
		Authorization => sprintf(
			'Basic %s',
			MIME::Base64::encode(
				join( ':', $self->api_username, $self->api_key )
			)
		)
	);
	return $client;
}

=method new( api_username => $api_username, api_key => $api_key )

Constructor method, requires both the C<api_username> and C<api_key> parameters be passed in.

=cut

=method auth($username, $password)

Authenticate for a specific customer account.  Returns a L<WWW::Shutterstock::Customer> object.

=cut

sub auth {
	my $self = shift;
	my $password = pop;
	my $username = pop || $self->api_username;
	$self->client->POST(
		'/auth/customer.json',
		{
			username => $username,
			password => $password
		}
	);
	my $auth_info = $self->client->process_response;
	if(ref($auth_info) eq 'HASH'){
		return WWW::Shutterstock::Customer->new( auth_info => $auth_info, client => $self->client );;
	} else {
		return $auth_info;
	}
}

=method categories

Returns a list of photo categories (useful for specifying a category_id when searching).

=cut

sub categories {
	my $self = shift;
	$self->client->GET('/categories.json');
	return $self->client->process_response;
}

=method search(%search_query)

Perform a search.  Accepts any params documented here: L<http://api.shutterstock.com/#imagessearch>.  Returns a L<WWW::Shutterstock::SearchResults> object.

=cut

sub search {
	my $self = shift;
	my %args = @_;
	return WWW::Shutterstock::SearchResults->new( client => $self->client, query => \%args );
}

=method image($image_id)

Performs a lookup on a single image.  Returns a L<WWW::Shutterstock::Image> object.

=cut

sub image {
	my $self = shift;
	my $image_id = shift;
	return WWW::Shutterstock::Image->new( image_id => $image_id, client => $self->client );
}

1;

=head1 SYNOPSIS

	my $ss = WWW::Shutterstock->new(
		api_username => 'justme',
		api_key      => 'abcdef1234567890'
	);

	# perform a search
	my $search = $ss->search( searchterm => 'blue cow' );

	# retrieve results of search
	my $results = $search->results;

	# details about a specific image (lookup by ID)
	my $image = $ss->image(123456789);

	# certain actions require credentials for a specific customer account
	my $account = $ss->auth( "myuser" => "mypassword" );

	my $media_subscription = $account->subscription('media');
	my $license = $media_subscription->license_image('123456789');

	# save the file locally as /my/photos/shutterstock_123456789.jpg
	$license->save("/my/photos");

	# save the file locally as /my/photos/favorite-pic.jpg
	$license->save("/my/photos/favorite-pic.jpg");

=cut
