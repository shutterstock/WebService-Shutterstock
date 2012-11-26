package WebService::Shutterstock::Exception;

# ABSTRACT: Exception object to allow for easy error handling on HTTP errors

use strict;
use warnings;

use Moo;
use overload q("") => \&to_string;

=attr request

The L<HTTP::Request> object for the API request that died.

=cut

has request  => ( is => 'lazy', required => 0, handles => ['uri', 'method'] );
sub _build_request {
	my $self = shift;
	return $self->response ? $self->response->request : undef;
}

=attr response

The L<HTTP::Response> object for the API request that died.

=cut

has response => ( is => 'ro', required => 0, handles => ['code'] );

=attr error

String error message.  Often, the body of the HTTP response that errored out.

=cut

has error    => ( is => 'ro', required => 1 );

=attr caller_info

A HashRef of information (package, file, line) of where this exception
originated (in non-WebService-Shutterstock land).

=cut

has caller_info => ( is => 'ro', required => 1 );

=for Pod::Coverage BUILDARGS

=cut

sub BUILDARGS {
	my $class = shift;
	my $args = $class->SUPER::BUILDARGS(@_);
	my $level = 0;
	while(!$args->{caller_info} || $args->{caller_info}->{package} =~ /^(Sub::Quote|WebService::Shutterstock)/){
		my @info = caller($level++) or last;
		$args->{caller_info} = { package => $info[0], file => $info[1], line => $info[2] };
	}
	$args->{caller_info} ||= { package => 'N/A', file => 'N/A', line => -1 };
	return $args;
}

=method to_string

Stringifies to error message, used by overloaded stringification.

=cut

sub to_string {
	my $self = shift;
	return sprintf("%s at %s line %s.\n", $self->error, $self->caller_info->{file}, $self->caller_info->{line});
}

1;

=head1 SYNOPSIS

	# better safe than sorry
	try {
		my $license = $customer->license($image_id)
		$license->save('/path/to/my/photos');
	} catch {
		my $error = $_;
		# handle error...
	};

=head1 DESCRIPTION

This class provides more context for an error message than just a simple
string (although it stringifies to make it act like your typical C<$@>
value).

=cut
