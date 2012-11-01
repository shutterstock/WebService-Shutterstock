package WWW::Shutterstock::Customer;

use strict;
use warnings;
use Moo;
use WWW::Shutterstock::Subscription;

with 'WWW::Shutterstock::AuthedClient';

has account_id => ( is => 'lazy' );
sub _build_account_id {
	my $self = shift;
	my $client = $self->client;
	$client->GET( sprintf( '/customers/%s.json', $self->username ), $self->with_auth_params );
	my $data = $client->process_response;
	return $data->{account_id};
}

has subscriptions => ( is => 'lazy' );
sub _build_subscriptions {
	my $self = shift;
	$self->client->GET( sprintf( '/customers/%s/subscriptions.json', $self->username ), $self->with_auth_params );
	my $subscriptions = $self->client->process_response;
	return [ map { $self->new_with_auth( 'WWW::Shutterstock::Subscription', %$_ ) } @$subscriptions ]
}

sub lightboxes {
	my $self = shift;
	my $extended = shift || 0;
	$self->client->GET(
		sprintf(
			'/customers/%s/lightboxes%s.json',
			$self->username, $extended ? '/extended' : ''
		),
		$self->with_auth_params
	);
	my $lightboxes = $self->client->process_response;
	return [ map {$self->new_with_auth('WWW::Shutterstock::Lightbox', %$_) } @$lightboxes ];
}

sub lightbox {
	my $self = shift;
	my $id = shift;
	return $self->new_with_auth('WWW::Shutterstock::Lightbox', lightbox_id => $id);
}

sub downloads {
	my $self = shift;
	$self->client->GET(
		sprintf( '/customers/%s/images/downloads.json', $self->username ),
		$self->with_auth_params );
	return $self->client->process_response;
}

sub subscription {
	my $self = shift;
	my $type = shift;
	my ($subscription) =  grep { $_->license eq $type } @{ $self->subscriptions };
	return $subscription;
}


1;
