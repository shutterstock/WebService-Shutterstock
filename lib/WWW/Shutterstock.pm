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

has api_username => (
	is => 'ro',
	required => 1,
);
has api_key => (
	is => 'ro',
	required => 1,
);
has username => (
	is => 'rwp',
	init_arg => 'undef',
);
has auth_token => (
	is => 'rwp',
	init_arg => 'undef',
);
has client_config => (
	is => 'ro',
	isa => sub { croak "client_config must be a HashRef" unless ref $_[0] eq 'HASH'; },
);

has _client => (
	is       => 'lazy',
	clearer  => 1,
);

sub _build__client {
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

sub auth {
	my $self = shift;
	my $password = pop;
	my $username = pop || $self->api_username;
	$self->_client->POST(
		'/auth/customer.json',
		{
			username => $username,
			password => $password
		}
	);
	my $auth_info = $self->_handle_response;
	if(ref($auth_info) eq 'HASH'){
		$self->_set_username( $auth_info->{username} );
		$self->_set_auth_token( $auth_info->{auth_token} );
	}
	return $auth_info;
}

sub require_auth {
	my $self = shift;
	if(!$self->username || !$self->auth_token){
		croak 'not authenticated yet, please call $ss->auth($username => $password) first.'
	}
}

sub categories {
	my $self = shift;
	$self->_client->GET('/categories.json');
	return $self->_handle_response;
}

sub lightboxes {
	my $self = shift;
	$self->require_auth;
	$self->_client->GET(
		sprintf( '/customers/%s/lightboxes.json', $self->username ),
		{ auth_token => $self->auth_token } );
	my $lightboxes = $self->_handle_response;
	return [ map { WWW::Shutterstock::Lightbox->new( %$_, ss => $self ) } @$lightboxes ];
}

sub _handle_response {
	my $self = shift;
	my %handlers = (
		204 => sub { 1 }, # empty response, but success
		401 => sub { croak "invalid api_username or api_key"; },
		@_
	);
	my $code = $self->_client->responseCode;
	my $content_type = $self->_client->responseHeader('Content-Type');

	my $response = $self->_client->{_res}; # blech, why isn't this public?
	my $request = $response->request;

	if(my $h = $handlers{$code}){
		$h->($response);
	} elsif($code <= 299){ # a success
		return $content_type =~ m{^application/json} && $self->_client->responseContent ? decode_json($self->_client->responseContent) : $response->decoded_content;
	} elsif($code <= 399){ # a redirect of some sort
		return $self->_client->responseHeader('Location');
	} elsif($code <= 499){ # client-side error
		croak sprintf('Error executing %s against %s: %s', $request->method, $request->uri, $response->status_line);
	} elsif($code >= 500){ # server-side error
		croak sprintf('Error executing %s against %s: %s', $request->method, $request->uri, $response->status_line);
	}
}

1;
