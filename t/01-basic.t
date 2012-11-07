use strict;
use warnings;
use Test::More;
use WWW::Shutterstock;
use Test::MockModule;

my $ss = WWW::Shutterstock->new(api_username => "test", api_key => 123);
isa_ok($ss, 'WWW::Shutterstock');

can_ok $ss, 'client';

{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('new', sub {
		my $class = shift;
		my %args = @_;
		is $args{host}, 'https://api.shutterstock.com', 'default host';
		return $guard->original('new')->($class, @_);
	});
	ok $ss->client, 'client initialized';
}

done_testing;
