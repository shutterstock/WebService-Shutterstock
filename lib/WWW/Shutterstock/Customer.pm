package WWW::Shutterstock::Customer;
BEGIN {
  $WWW::Shutterstock::Customer::AUTHORITY = 'cpan:BPHILLIPS';
}
{
  $WWW::Shutterstock::Customer::VERSION = '0.001';
}

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


has subscriptions => ( is => 'lazy' );
sub _build_subscriptions {
	my $self = shift;
	$self->client->GET( sprintf( '/customers/%s/subscriptions.json', $self->username ), $self->with_auth_params );
	my $subscriptions = $self->client->process_response;
	return [ map { $self->new_with_auth( 'WWW::Shutterstock::Subscription', %$_ ) } @$subscriptions ]
}


sub subscription {
	my $self = shift;
	my $type = shift;
	my ($subscription) =  grep { $_->license eq $type } @{ $self->subscriptions };
	return $subscription;
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

1;

__END__

=pod

=head1 NAME

WWW::Shutterstock::Customer - Class allowing API operations in the context of a specific customer

=head1 VERSION

version 0.001

=head1 SYNOPSIS

	my $customer = $ss->auth("my-user" => "my-password");

	# retrieve list of lightboxes
	my $lightboxes = $customer->ligthboxes;

	# retrieve a specific lightbox for this user
	my $lightbox = $customer->lightbox(123);

	my $subscriptions = $customer->subscriptions;
	my $premier_subscription = $customer->subscription('premier');

	my $download_history = $customer->downloads;

=head1 DESCRIPTION

This class provides access to API operations (download history, lightbox interaction, subscriptions, etc) that require an authenticated
customer (via L<WWW::Shutterstock/"auth">).

=head1 METHODS

=head2 account_id

Retrieves the account ID for this account.

=head2 subscriptions

Returns an ArrayRef of L<WWW::Shutterstock::Subscription> objects for this customer account.

=head2 subscription

Retrieve a specific L<WWW::Shutterstock::Subscription> object, based on the type of subscription (i.e. "premier", "premier_digitial", "media", "media_digital")

=head2 lightboxes($get_extended_info)

Returns an ArrayRef of L<WWW::Shutterstock::Lightbox> objects for this
customer acount.  By default, it gets only the lightbox information and
the list of image IDs in the lightbox.  If you would like to retrieve
more details about those images (specifically sizes and thumbnail URLs)
in a single HTTP request, just pass a true value as the only argument
to this method.

=head2 lightbox($id)

Returns a specific lightbox (as a L<WWW::Shutterstock::Lightbox> object) for the given C<$id> (it must belong to this user).

=head2 downloads

Retrieve the download history for this customer account.

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
