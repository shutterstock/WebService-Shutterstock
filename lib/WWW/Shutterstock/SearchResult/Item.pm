package WWW::Shutterstock::SearchResult::Item;

use strict;
use warnings;
use Moo;

with 'WWW::Shutterstock::HasClient';

has photo_id => ( is => 'ro' ); # sic, should be image_id to be consistant I think

has thumb_small => ( is => 'ro' );
has thumb_large => ( is => 'ro' );
has preview     => ( is => 'ro' );

has web_url     => ( is => 'ro' );
has description => ( is => 'ro' );

sub image {
	my $self = shift;
	return $self->new_with_client( 'WWW::Shutterstock::Image', image_id => $self->photo_id );
}

1;
