package WebService::Shutterstock::SearchResults;

# ABSTRACT: Class representing a single page of search results from the Shutterstock API

use strict;
use warnings;
use Moo;
use WebService::Shutterstock::SearchResult::Image;
use WebService::Shutterstock::SearchResult::Video;

with 'WebService::Shutterstock::HasClient';

sub BUILD { shift->_results_data } # eagar loading

=for Pod::Coverage BUILD _results_data

=attr query

A HashRef of the arguments used to perform the search.

=cut

=attr type

Indicates whether these are "image" or "video" search results.

=cut

has type => (
	is => 'ro',
	required => 1,
	isa => sub {
		die 'invalid type (expected "image" or "video")' unless $_[0] eq 'image' or $_[0] eq 'video';
	}
);

has query => (
	is       => 'ro',
	required => 1,
	isa      => sub { die "query must be a HashRef" unless ref $_[0] eq 'HASH' }
);
has _results_data => ( is => 'lazy' );

sub _build__results_data {
	my $self = shift;
	my $client = $self->client;
	$client->GET(sprintf('/%ss/search.json', $self->type), $self->query);
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

Returns an ArrayRef of L<WebService::Shutterstock::SearchResult::Image>
or L<WebService::Shutterstock::SearchResult::Video> objects for this
page of search results (based on the C<type> of this set of search
results).

=cut

sub results {
	my $self = shift;
	my $item_class = $self->type eq 'image' ? 'WebService::Shutterstock::SearchResult::Image' : 'WebService::Shutterstock::SearchResult::Video';
	return [
		map {
			$self->new_with_client( $item_class, %$_ );
		}
		@{ $self->_results_data->{results} || [] }
	];
}

=method iterator

Returns an iterator as a CodeRef that will return results in order until
all results are exhausted (walking from one page to the next as needed).

See the L<SYNOPSIS> for example usage.

=cut

sub iterator {
	my $self = shift;
	my $count = $self->count;
	my $search_results = $self;
	my $batch;
	my $batch_i = my $i = my $done = 0;
	return sub {
		return if $i >= $count;
		my $item;
		if(!$batch){
			$batch = $search_results->results;
		} elsif($batch_i >= @$batch){
			$batch_i = 0;
			eval {
				$search_results = $search_results->next_page;
				$batch = $search_results->results;
				1;
			} or do {
				warn $@;
				$done = 1;
			};
		}
		return if !$batch || $done;

		$item = $batch->[$batch_i];
		$i++;
		$batch_i++;
		return $item;
	};
}

=method next_page

Retrieves the next page of search results (represented as a
L<WebService::Shutterstock::SearchResults> object).  This is just a shortcut
for specifying a specific C<page_number> in the arguments to the
L<search|WebService::Shutterstock/search> method.

=cut

sub next_page {
	my $self = shift;
	my $query = { %{ $self->query } };
	$query->{page_number} ||= 0;
	$query->{page_number}++;
	return WebService::Shutterstock::SearchResults->new( client => $self->client, query => $query, type => $self->type );
}

1;

=head1 SYNOPSIS

	my $search = $shutterstock->search(searchterm => 'butterfly');

	# grab results a page at a time
	my $results = $search->results;
	my $next_results = $search->next_page;

	# or use an iterator
	my $iterator = $search->iterator;
	while(my $result = $iterator->()){
		# ...
	}

=cut
