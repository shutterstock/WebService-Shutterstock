package WebService::Shutterstock::SearchResult::Item;

# ABSTRACT: role representing common attributes for various search result types

use strict;
use warnings;
use Moo::Role;

has web_url     => ( is => 'ro' );
has description => ( is => 'ro' );

=attr web_url

=attr description

=cut

1;
