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

$ss = WWW::Shutterstock->new(api_username => "test", api_key => 123);
{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('new', sub {
		my $class = shift;
		my %args = @_;
		is $args{host}, 'https://testing.com', 'override host';
		return $guard->original('new')->($class, @_);
	});
	local $ENV{SS_API_HOST} = 'https://testing.com';
	ok $ss->client, 'client initialized with non-default host';
}

done_testing;
