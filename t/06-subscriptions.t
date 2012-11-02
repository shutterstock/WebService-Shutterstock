use strict;
use warnings;
use Test::More;
use WWW::Shutterstock;
use Test::MockModule;

my $client = WWW::Shutterstock::Client->new;
my $customer = WWW::Shutterstock::Customer->new(
	auth_info => { auth_token => 123, username => 'abc' },
	client    => $client
);
isa_ok($customer, 'WWW::Shutterstock::Customer');

can_ok $customer, 'subscriptions';

{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('GET', sub {
		my($self, $url) = @_;
		like $url, qr'/customers/abc/subscriptions.json\?', 'correct URL';
		like $url, qr{auth_token=123}, 'includes auth_token';
		return $self->response(
			response(
				200,
				'[{"subscription_id":1,"unix_expiration_time":0,"license":"premier"},{"subscription_id":2,"unix_expiration_time":0,"license":"premier_digital"}]'
			)
		);
	});
	my $subscriptions = $customer->subscriptions;
	is @$subscriptions, 2, 'has subscriptions';
	isa_ok $subscriptions->[0], 'WWW::Shutterstock::Subscription';
	is $subscriptions->[0]->id, 1, 'has correct data';
	ok $subscriptions->[0]->is_expired, 'is_expired';
	ok !$subscriptions->[0]->is_active, 'is_active';
	is $customer->subscription('premier_digital')->id, 2, 'license lookup for subscription';

	$guard->mock('POST', sub {
		my($self, $url, $content) = @_;
		is $url, q{/subscriptions/2/images/1/sizes/medium.json}, 'correct URL';
		like $content, qr{format=jpg}, 'has format';
		like $content, qr{auth_token=123}, 'has auth_token';
		like $content, qr{metadata=%7B%22key}, 'has metadata';
		return $self->response(
			response(
				200,
				'{"photo_id":"14184","thumb_large":{"url":"http://thumb10.shutterstock.com/photos/thumb_large/yoga/IMG_0095.JPG","img":"http://thumb10.shutterstock.com/photos/thumb_large/yoga/IMG_0095.JPG"},"allotment_charge":0,"download":{"url":"http://download.shutterstock.com/gatekeeper/testing/shutterstock_1.jpg"}}
				'
			)
		);
	});

	my $image = $customer->subscription('premier_digital')->license_image(1 => 'medium', { key => 'value' });
	my $lwp = Test::MockModule->new('LWP::Simple');
	my $desired_dest;
	$lwp->mock('getstore', sub ($$) {
		my($url, $dest) = @_;
		is $url, 'http://download.shutterstock.com/gatekeeper/testing/shutterstock_1.jpg', 'has correct download URL';
		is $dest, $desired_dest, 'has correct destination';
	});
	$image->save($desired_dest = '/tmp/foo');
	$desired_dest = './shutterstock_1.jpg';
	$image->save('./');
}

done_testing;

sub response {
	@_ = [@_] unless ref $_[0] eq 'ARRAY';
	my $code = $_[0]->[0];
	my $data = $_[0]->[1];

	my $method = $_[1]->[0] || 'GET';
	my $uri = $_[1]->[1] || '/';

	my $response = HTTP::Response->new( $code, undef, ['Content-Type' => 'application/json'], $data );
	$response->request(HTTP::Request->new( $method, $uri ));
	return $response;
}
