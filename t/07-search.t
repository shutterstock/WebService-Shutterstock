use strict;
use warnings;
use Test::More;
use WWW::Shutterstock;
use Test::MockModule;

my $ss = WWW::Shutterstock->new(api_username => "test", api_key => 123);

can_ok $ss, 'search';
{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('GET', sub {
		my $self = shift;
		like $_[0], qr{^/images/search.json}, 'GETs correct URL';
		like $_[0], qr{searchterm=cat},       'has correct search term';
		my ($page) = $_[0] =~ m/page_number=(\d+)/;
		$ss->client->response(
			response(
				200,
				[ 'Content-Type' => 'application/json' ],
				'{"count":"9337","page":"'
				  . ( $page || 0 )
				  . '","searchSrcID":"","sort_method":"popular","results":[{"photo_id":1},{"photo_id":2}]}'
			)
		);
	});
	my $search = $ss->search(searchterm => 'cat');
	is $search->count, 9337, 'has count';
	is $search->sort_method, 'popular', 'has sort_method';
	is $search->page, 0, 'first page';
	$search = $search->next_page;
	is $search->page, 1, 'next page';
	my $results = $search->results;
	is @$results, 2, 'has correct number of results';
	my $image = $results->[0]->image;
	is $image->id, 1, 'has correct image ID';
}

done_testing;

sub response {
	@_ = [@_] unless ref $_[0] eq 'ARRAY';
	my $code = $_[0]->[0];
	my $headers = $_[0]->[1];
	my $data = $_[0]->[2];
	my $method = $_[1]->[0] || 'GET';
	my $uri = $_[1]->[1] || '/';
	my $response = HTTP::Response->new( $code, undef, $headers, $data );
	$response->request(HTTP::Request->new( $method, $uri ));
	return $response;
}
