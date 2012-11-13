package WWW::Shutterstock::SearchResults;
BEGIN {
  $WWW::Shutterstock::SearchResults::AUTHORITY = 'cpan:BPHILLIPS';
}
{
  $WWW::Shutterstock::SearchResults::VERSION = '0.001';
}

# ABSTRACT: Class representing a single page of search results from the Shutterstock API

use strict;
use warnings;
use Moo;
use WWW::Shutterstock::SearchResult::Item;

with 'WWW::Shutterstock::HasClient';

sub BUILD { shift->_results_data } # eagar loading


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

__END__

=pod

=head1 NAME

WWW::Shutterstock::SearchResults - Class representing a single page of search results from the Shutterstock API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

	my $search = $shutterstock->search(searchterm => 'butterfly');
	my $results = $search->results;

	my $next_results = $search->next_page;

=head1 ATTRIBUTES

=head2 query

A HashRef of the arguments used to perform the search.

=head2 page

The current page of the search results (0-based).

=head2 count

The total number of search results.

=head2 sort_method

The sort method used to perform the search.

=head1 METHODS

=head2 results

Returns an ArrayRef of L<WWW::Shutterstock::SearchResult::Item> for this
page of search results.

=head2 next_page

Retrieves the next page of search results (represented as a
L<WWW::Shutterstock::SearchResults> object).  This is just a shortcut
for specifying a specific C<page_number> in the arguments to the
L<search|WWW::Shutterstock/search> method.

=for Pod::Coverage BUILD _results_data

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
