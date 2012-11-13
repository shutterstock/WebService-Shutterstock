package WWW::Shutterstock::Customer;

# ABSTRACT: Class allowing API operations in the context of a specific customer

use strict;
use warnings;
use Moo;
use WWW::Shutterstock::Subscription;
use Carp qw(croak);

with 'WWW::Shutterstock::AuthedClient';

=method account_id

Retrieves the account ID for this account.

=cut

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

Convenience wrapper around the C<find_subscriptions> method that always
returns the first match (useful when you're matching on a field that is
unique like C<id> or C<license>).

	# find the (single) subscription providing an enhanced license
	my $media_digital_subscription = $customer->subscription(license => 'enhanced');

=cut

sub subscription {
	my $self = shift;
	my($subscription) = $self->find_subscriptions(@_);
	return $subscription;
}

=method find_subscriptions

Retrieve a list of L<WWW::Shutterstock::Subscription> objects, based
on the criteria passed in to the method. Filter criteria should have
L<WWW::Shutterstock::Subscription> attribute names as keys with the value
to be matched as the value.  Subscriptions that match ALL the provided
criteria are returned as a list.  Some examples:

	# simple equality filters
	my @active_subscriptions = $customer->find_subscriptions( is_active => 1 );
	my @active_subscriptions = $customer->find_subscriptions( is_active => 1 );

	# regular expressions work too
	my @all_media_subscriptions = $customer->find_subscriptions( license => qr{^media} );

	# use an anonymous sub for more detailed filters (i.e. subscriptions expiring in the 
	my @soon_to_expire = $customer->find_subscriptions(
		is_active            => 1,
		unix_expiration_time => sub { shift < time + ( 60 * 60 * 24 * 30 ) }
	);

=cut

sub find_subscriptions {
	my $self = shift;
	my %criteria = @_;
	my $filter = sub {
		my $s = shift;
		foreach my $m(keys %criteria){
			croak "Invalid subscription filter key '$m': no such attribute on WWW::Shutterstock::Subscription" if !$s->can($m);
			my $value = $s->$m;
			my $matcher = $criteria{$m};
			if(ref $matcher eq 'CODE'){
				local $_ = $value;
				return unless $matcher->($value);
			} elsif(ref $matcher eq 'Regexp'){
				return unless $value =~ $matcher;
			} else {
				return unless $value eq $matcher;
			}
		}
		return 1;
	};
	return grep { $filter->($_) } @{ $self->subscriptions };
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

Returns a specific lightbox (as a L<WWW::Shutterstock::Lightbox> object)
for the given C<$id> (it must belong to this user).  If that lightbox
doesn't exist, C<undef> will be returned.  Unfortunately, Shutterstock's
API currently returns an HTTP status of C<500> on an unknown lightbox ID
(which could mask other error situations).

=cut

sub lightbox {
	my $self = shift;
	my $id = shift;
	my $lightbox = $self->new_with_auth('WWW::Shutterstock::Lightbox', lightbox_id => $id);
	eval { $lightbox->load; 1 } or do {
		my $e = $@;
		if(eval { $e->isa('WWW::Shutterstock::Exception') } && ($e->code eq 404 || $e->code eq 500)){
			$lightbox = undef;
		} else {
			die $e;
		}
	};
	return $lightbox;
}

=method downloads

Retrieve the download history for this customer account.  The data
returned will look something like this:

	[
		{
			image_id => 1,
			license  => 'standard',
			time     => '2012-11-01 14:16:08',
		},
		{
			image_id => 2,
			license  => 'premier',
			metadata => { purchase_order => 'XYZ', client => 'My Client' },
			time     => '2012-11-01 14:18:39',
		},
		# etc...
	]

=cut

sub downloads {
	my $self = shift;
	$self->client->GET(
		sprintf( '/customers/%s/images/downloads.json', $self->username ),
		$self->with_auth_params );
	return $self->client->process_response;
}

1;

=head1 SYNOPSIS

	my $customer = $shutterstock->auth("my-user" => "my-password");

	# retrieve list of lightboxes
	my $lightboxes = $customer->ligthboxes;

	# retrieve a specific lightbox for this user
	my $lightbox = $customer->lightbox(123);

	my $subscriptions = $customer->subscriptions;
	my $premier_subscription = $customer->subscription(license => 'premier');

	my $download_history = $customer->downloads;

=head1 DESCRIPTION

This class provides access to API operations (download history, lightbox interaction, subscriptions, etc) that require an authenticated
customer (via L<WWW::Shutterstock/"auth">).

=cut
