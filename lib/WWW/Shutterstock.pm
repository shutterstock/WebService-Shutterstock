package WWW::Shutterstock;

# ABSTRACT: Easy access to Shutterstock's public API

use strict;
use warnings;

use Moo 1;
use REST::Client;
use MIME::Base64;
use JSON qw(encode_json decode_json);
use WWW::Shutterstock::Lightbox;
use WWW::Shutterstock::Client;
use WWW::Shutterstock::Customer;
use WWW::Shutterstock::SearchResults;
use WWW::Shutterstock::Exception;

has api_username => (
	is => 'ro',
	required => 1,
);
has api_key => (
	is => 'ro',
	required => 1,
);
has client => (
	is       => 'lazy',
	clearer  => 1,
);

sub _build_client {
	my $self = shift;
	my $client = WWW::Shutterstock::Client->new( host => $ENV{SS_API_HOST} || 'https://api.shutterstock.com' );
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

=method auth(username => $username, password => $password)

Authenticate for a specific customer account.  Returns a
L<WWW::Shutterstock::Customer> object.  If authentication fails, an
exception is thrown (see L<WWW::Shutterstock::Exception> and L</"ERRORS">
section for more information).

=cut

sub auth {
	my $self = shift;
	my %args = @_;
	$args{username} ||= $self->api_username;
	if(!$args{password}){
		die WWW::Shutterstock::Exception->new( error => "missing 'password' param for auth call");
	}
	$self->client->POST(
		'/auth/customer.json',
		{
			username => $args{username},
			password => $args{password}
		}
	);
	my $auth_info = $self->client->process_response;
	if(ref($auth_info) eq 'HASH'){
		return WWW::Shutterstock::Customer->new( auth_info => $auth_info, client => $self->client );;
	} else {
		die WWW::Shutterstock::Exception->new(
			response => $self->client->response,
			error    => "Error authenticating $args{username}: $auth_info"
		);
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

Performs a lookup on a single image.  Returns a L<WWW::Shutterstock::Image> object (or C<undef> if the image doesn't exist).

=cut

sub image {
	my $self = shift;
	my $image_id = shift;
	my $image = WWW::Shutterstock::Image->new( image_id => $image_id, client => $self->client );
	return $image->is_available ? $image : undef;
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
	my $account = $ss->auth( username => "myuser", password => "mypassword" );

	# history of downloaded images across all subscriptions
	my $history = $account->downloads;

	my $media_subscription = $account->subscription('media');
	my $license = $media_subscription->license_image('123456789');

	# save the file locally as /my/photos/shutterstock_123456789.jpg
	$license->save("/my/photos");

	# save the file locally as /my/photos/favorite-pic.jpg
	$license->save("/my/photos/favorite-pic.jpg");

=head1 DESCRIPTION

This module provides an easy way to interact with the L<Shutterstock, Inc. API|http://api.shutterstock.com>.
You will need an API username and key from Shutterstock with the
appropriate permissions in order to use this module.

=head3 Errors

If you provide an invalid C<api_username> or C<api_key>, the first request
executed will die with a L<WWW::Shutterstock::Exception> object.
This exception object should have the necessary information for you to
diagnose what exactly went wrong (including the full request and response
objects that preceded the error).  L<WWW::Shutterstock::Exception> objects
will be thrown on unexpected errors as well.

=cut
