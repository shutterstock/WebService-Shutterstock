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

Constructor method, requires both the C<api_username> and C<api_key>
parameters be passed in.  If you provide invalid values that the API
doesn't recognize, the first API call you make will throw an exception

=cut

=method auth(username => $username, password => $password)

Authenticate for a specific customer account.  Returns a
L<WWW::Shutterstock::Customer> object.  If authentication fails, an
exception is thrown (see L<WWW::Shutterstock::Exception> and L</"ERRORS">
section for more information).

This is the main entry point for any operation dealing with subscriptions,
image licensing, download history or lightboxes.

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

	my $shutterstock = WWW::Shutterstock->new(
		api_username => 'justme',
		api_key      => 'abcdef1234567890'
	);

	# perform a search
	my $search = $shutterstock->search( searchterm => 'hummingbird' );

	# retrieve results of search
	my $results = $search->results;

	# details about a specific image (lookup by ID)
	my $image = $shutterstock->image( 59915404 );

	# certain actions require credentials for a specific customer account
	my $customer = $shutterstock->auth( username => $customer, password => $password );

=head1 DESCRIPTION

This module provides an easy way to interact with the L<Shutterstock,
Inc. API|http://api.shutterstock.com>.  You will need an API username
and key from Shutterstock with the appropriate permissions in order to
use this module.

While there are some actions you can perform with this object (as shown
under the L</METHODS> section), many API operations are done within
the context of a specific user/account or a specific subscription.
Below are some additional examples of how to use this set of API modules.
You will find more examples and documentation in the related modules as
well as the C<examples> directory in the source of the distribution.

=head3 Licensing and Downloading

Licensing images happens in the context of a
L<WWW::Shutterstock::Customer> object.  For example:

	my $licensed_image = $customer->license_image(
		image_id => 59915404,
		size     => 'medium'
	);

If you have more than one active subscription, you will need to
specify which subscription to license the image under.  Please see
L<WWW::Shutterstock::Customer/license_image> for more details.

Once you have a L<licensed image|WWW::Shutterstock::LicensedImage>,
you can then download the image:

	$licensed_image->download(file => '/my/photos/hummingbird.jpg');

Every image licensed under your account (whether through shutterstock.com or the
API) can be retrieved using the L<customer|WWW::Shutterstock::Customer>
object as well:

	my $downloads = $customer->downloads;

=head3 Lightboxes

Lightbox retrieval starts with a L<customer|WWW::Shutterstock::Customer>
as well but most methods are documented in the
L<WWW::Shutterstock::Lightbox> module.  Here's a short example:

	my $lightboxes = $customer->lightboxes;
	my($favorites) = grep {$_->name eq 'Favorites'} @$lightboxes;
	$favorites->add_image(59915404);

	my $favorite_images = $favorite->images;

=head1 ERROR HANDLING

If an API call fails in an unexpected way, an exception object (see
L<WWW::Shutterstock::Exception>) will be thrown.  This object should
have all the necessary information for you to handle the error if you
choose but also stringifies to something informative enough to be
useful as well.

=cut
