package WWW::Shutterstock::SearchResults;

use strict;
use warnings;
use Moo;
use WWW::Shutterstock::SearchResult::Item;

with 'WWW::Shutterstock::HasClient';

sub BUILD { shift->_results_data } # eagar loading

has query => ( is => 'ro', required => 1, isa => sub { die "query must be a HashRef" unless ref $_[0] eq 'HASH' } );
has _results_data => ( is => 'lazy' );

sub _build__results_data {
	my $self = shift;
	my $client = $self->client;
	$client->GET('/images/search.json', $self->query);
	return $client->process_response;
}

sub page        { return shift->_results_data->{page} }
sub count       { return shift->_results_data->{count} }
sub sort_method { return shift->_results_data->{sort_method} }

sub results {
	my $self = shift;
	return [
		map {
			$self->new_with_client( 'WWW::Shutterstock::SearchResult::Item', %$_ );
		}
		@{ $self->_results_data->{results} || [] }
	];
}

sub next_page {
	my $self = shift;
	my $query = { %{ $self->query } };
	$query->{page_number} ||= 0;
	$query->{page_number}++;
	return WWW::Shutterstock::SearchResults->new( client => $self->client, query => $query );
}

1;
