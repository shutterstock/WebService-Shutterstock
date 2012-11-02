package WWW::Shutterstock::Customer;

# ABSTRACT: Class allowing API operations in the context of a specific customer

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

=method subscriptions

Returns an ArrayRef of L<WWW::Shutterstock::Subscription> objects for this customer account.

=cut

has subscriptions => ( is => 'lazy' );
sub _build_subscriptions {
	my $self = shift;
	$self->client->GET( sprintf( '/customers/%s/subscriptions.json', $self->username ), $self->with_auth_params );
	my $subscriptions = $self->client->process_response;
	return [ map { $self->new_with_auth( 'WWW::Shutterstock::Subscription', %$_ ) } @$subscriptions ]
}

=method subscription

Retrieve a specific L<WWW::Shutterstock::Subscription> object, based on the type of subscription (i.e. "premier", "premier_digitial", "media", "media_digital")

=cut

sub subscription {
	my $self = shift;
	my $type = shift;
	my ($subscription) =  grep { $_->license eq $type } @{ $self->subscriptions };
	return $subscription;
}

=method lightboxes($get_extended_info)

Returns an ArrayRef of L<WWW::Shutterstock::Lightbox> objects for this
customer acount.  By default, it gets only the lightbox information and
the list of image IDs in the lightbox.  If you would like to retrieve
more details about those images (specifically sizes and thumbnail URLs)
in a single HTTP request, just pass a true value as the only argument
to this method.

=cut

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

=method lightbox($id)

Returns a specific lightbox (as a L<WWW::Shutterstock::Lightbox> object) for the given C<$id> (it must belong to this user).

=cut

sub lightbox {
	my $self = shift;
	my $id = shift;
	return $self->new_with_auth('WWW::Shutterstock::Lightbox', lightbox_id => $id);
}

=method downloads

Retrieve the download history for this customer account.

=cut

sub downloads {
	my $self = shift;
	$self->client->GET(
		sprintf( '/customers/%s/images/downloads.json', $self->username ),
		$self->with_auth_params );
	return $self->client->process_response;
}

1;
