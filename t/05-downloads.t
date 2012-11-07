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

can_ok $customer, 'downloads';

{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('GET', sub {
		my($self, $url) = @_;
		like $url, qr'/customers/abc/images/downloads.json\?', 'correct URL';
		like $url, qr{auth_token=123}, 'includes auth_token';
		return $self->response(
			response(
				200,
				'{"123123":[{"time":"2012-01-01 00:00:00","image_id":"123","metadata":{"purchase_order":"purchase order"},"license":"premier"}]}'
			)
		);
	});
	my $downloads = $customer->downloads;
	ok exists $downloads->{123123}, 'has subscription 123123';
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
