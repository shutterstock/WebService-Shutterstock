use strict;
use warnings;
use Test::More;
use WWW::Shutterstock;
use Test::MockModule;

my $ss = WWW::Shutterstock->new(api_username => "test", api_key => 123, client_config => {timeout => 60});
isa_ok($ss, 'WWW::Shutterstock');

$ss->_set_username('foo');
$ss->_set_auth_token('123');

can_ok $ss, 'lightboxes';

{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('GET', sub {
		my($self, $url) = @_;
		like $url, qr'/customers/foo/lightboxes.json\?', 'correct URL';
		like $url, qr{auth_token=123}, 'includes auth_token';
		return $self->{_res} = response(200, '[{"lightbox_id":1,"lightbox_name":"test","images":[{"image_id":1}]},{"lightbox_id":2, "lightbox_name":"test 2","images":[{"image_id":2}]}]');
	});
	my $lightboxes = $ss->lightboxes;
	is @$lightboxes, 2, 'has two lightboxes';
	is $lightboxes->[1]->id, 2, 'correct data - id';
	is $lightboxes->[1]->name, 'test 2', 'correct data - name';

	$guard->mock('PUT' => sub {
		my($self, $url) = @_;
		like $url, qr{/lightboxes/1/images/123\?}, 'correct URL (PUT)';
		like $url, qr{username=foo&auth_token=123}, 'has username/auth (PUT)';
	});
	$lightboxes->[0]->add_image(123);

	$guard->mock('DELETE' => sub {
		my($self, $url) = @_;
		like $url, qr{/lightboxes/1/images/123\?}, 'correct URL (DELETE)';
		like $url, qr{username=foo&auth_token=123}, 'has username/auth (DELETE)';
	});
	$lightboxes->[0]->delete_image(123);
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
