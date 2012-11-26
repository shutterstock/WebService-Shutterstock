#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use WebService::Shutterstock;

my($api_user, $api_key, $username, $password, %subscription_filter, $image_id, $size, $file, $directory, %metadata, $help);
GetOptions(
	"api-user=s"     => \$api_user,
	"api-key=s"      => \$api_key,
	"username=s"     => \$username,
	"password=s"     => \$password,
	"subscription=s" => \%subscription_filter,
	"image=i"        => \$image_id,
	"size=s"         => \$size,
	"metadata=s"     => \%metadata,
	"file=s"         => \$file,
	"directory=s"    => \$directory,
	"help"           => \$help
);
usage(-1) if grep { !defined($_) } ($api_user, $api_key, $username, $password, $image_id, $size);
usage(-1) if !$file && !$directory;

usage() if $help;

my $shutterstock = WebService::Shutterstock->new( api_username => $api_user, api_key => $api_key );
my $user = $shutterstock->auth( username => $username, password => $password );

my $licensed_image = $user->license_image(
	image_id => $image_id,
	size     => $size,
	( keys %metadata ? ( metadata => \%metadata ) : () ),
	(
		keys %subscription_filter
		? ( subscription => \%subscription_filter )
		: ()
	)
);

my $saved;
if ($directory) {
	$saved = $licensed_image->download( directory => $directory );
} elsif ( $file eq '-' ) {
	binmode(STDOUT);
	print $licensed_image->download;
} elsif ($file) {
	$saved = $licensed_image->download( file => $file );
}

if($saved){
	print "Saved image to $saved\n";
}

sub usage {
	my $error = shift;
	print <<"_USAGE_";
usage: $0 --api-user justme --api-key abc123 --username my_user --password my_password --image 59915404 --size medium --directory .
_USAGE_
	exit $error || 0;
}
