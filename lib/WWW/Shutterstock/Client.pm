package WWW::Shutterstock::Client;

use strict;
use warnings;
use Moo;

extends 'REST::Client';

sub response {
	my $self = shift;
	if(@_){
		$self->{_res} = $_[0];
	}
	return $self->{_res};
}

sub GET {
	my($self, $url, $content, $headers) = @_;
	if(ref($content) eq 'HASH'){
		$url .= $self->buildQuery(%$content);
	}
	$self->SUPER::GET($url, $headers);
	return $self->response;
}

sub PUT {
	my($self, $url, $content, $headers) = @_;
	if(ref($content) eq 'HASH'){
		my $uri = URI->new();
		$uri->query_form(%$content);
		$content = $uri->query;
		$headers ||= {};
		$headers->{'Content-Type'} = 'application/x-www-form-urlencoded';
	}
	$self->SUPER::PUT($url, $content, $headers);
	return $self->response;
}

sub POST {
	my($self, $url, $content, $headers) = @_;
	if(ref($content) eq 'HASH'){
		my $uri = URI->new();
		$uri->query_form(%$content);
		$content = $uri->query;
		$headers ||= {};
		$headers->{'Content-Type'} = 'application/x-www-form-urlencoded';
	}
	$self->SUPER::POST($url, $content, $headers);
	return $self->response;
}

1;
