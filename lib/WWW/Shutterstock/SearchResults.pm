package WWW::Shutterstock::SearchResults;

# ABSTRACT: Class representing a single page of search results from the Shutterstock API

use strict;
use warnings;
use Moo;
use WWW::Shutterstock::SearchResult::Item;

with 'WWW::Shutterstock::HasClient';

sub BUILD { shift->_results_data } # eagar loading

=for Pod::Coverage BUILD _results_data

=attr query

A HashRef of the arguments used to perform the search.

=cut

has query => (
	is       => 'ro',
	required => 1,
	isa      => sub { die "query must be a HashRef" unless ref $_[0] eq 'HASH' }
);
has _results_data => ( is => 'lazy' );

sub _build__results_data {
	my $self = shift;
	my $client = $self->client;
	$client->GET('/images/search.json', $self->query);
	return $client->process_response;
}

=attr page

The current page of the search results (0-based).

=attr count

The total number of search results.

=attr sort_method

The sort method used to perform the search.

=cut

sub page        { return shift->_results_data->{page} }
sub count       { return shift->_results_data->{count} }
sub sort_method { return shift->_results_data->{sort_method} }

=method results

Returns an ArrayRef of L<WWW::Shutterstock::SearchResult::Item> for this
page of search results.

=cut

sub results {
	my $self = shift;
	return [
		map {
			$self->new_with_client( 'WWW::Shutterstock::SearchResult::Item', %$_ );
		}
		@{ $self->_results_data->{results} || [] }
	];
}

=method next_page

Retrieves the next page of search results (represented as a
L<WWW::Shutterstock::SearchResults> object).  This is just a shortcut
for specifying a specific C<page_number> in the arguments to the
L<search|WWW::Shutterstock/search> method.

=cut

sub next_page {
	my $self = shift;
	my $query = { %{ $self->query } };
	$query->{page_number} ||= 0;
	$query->{page_number}++;
	return WWW::Shutterstock::SearchResults->new( client => $self->client, query => $query );
}

1;

=head1 SYNOPSIS

	my $search = $shutterstock->search(searchterm => 'butterfly');
	my $results = $search->results;

	my $next_results = $search->next_page;

=cut
