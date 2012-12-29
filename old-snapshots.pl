#!/usr/bin/perl

#
# 	old-snapshots.pl [aging-days]
#
#		aging-days - find snapshots older than X days (Optional, default value is 30 days)
#
#	Return:
#	0 - at least one old napshot found
#	1 - no old snapshoths found
#
#	Because of nature of "snap list" output we can't find snapshots older than 1 year!
#
#   Author: dusan.sovi
#

# Example of Output to parse: sudo /usr/bin/rsh poseidon snap list
#
#   %/used       %/total  date          name
# ----------  ----------  ------------  --------
#  9% ( 9%)    3% ( 3%)  Sep 05 00:42  SOADEV_cold_PSU_JULY_2012
# 10% ( 1%)    3% ( 0%)  Jul 11 01:34  SOADEV_B4_HP_Support
#
# Note: There is no information about YEAR in date column !!!
#
# Example of use:
# $ sudo /usr/bin/rsh poseidon snap list|old-snapshots.pl 60
#

use strict;
use warnings;
use Time::Local;

my %month2num = (
	"Jan" =>  0,
	"Feb" =>  1, 
	"Mar" =>  2, 
	"Apr" =>  3,
	"May" =>  4,
	"Jun" =>  5,
	"Jul" =>  6,
	"Aug" =>  7, 
	"Sep" =>  8,
	"Oct" =>  9,
	"Nov" => 10,  
	"Dec" => 11,
);

my $OLDER_THAN_DAYS = 30; # can be overrided by 1st script argument ARGV[0]
my $volumeName ="";
my $foundOlder = 0;
my $TIME_NOW = time; # get epoch time
my ($MONTH_NOW, $YEAR_NOW) = (localtime($TIME_NOW))[4,5]; # get year from epoch time real date => +1900

if ( defined($ARGV[0]) )  {
	$OLDER_THAN_DAYS = $ARGV[0];
}

#print "  %/used       %/total  date          name";
#print "----------  ----------  ------------  --------";

while (<STDIN>) {
	chomp;
	if (/^Volume (.*)$/) { $volumeName = "$1"; next; }
	if (/^No snapshots exist.*$/) { $volumeName = "" ; next; }	
	
	# Snapshot found => process it (compute delta time)
	if (/(\w{3}) (\d\d) (\d\d:\d\d)\s+(.*)/) {
		# get date from pattern
		my ($snapshotTime, $year, $month, $day) = (0, 0, $1, $2);

		# snapshots from previous year?
		if ( $month2num{$month} > $MONTH_NOW ) {
			$year = $YEAR_NOW - 1;
			# convert to epoch for comparasion
			$snapshotTime = timelocal(0, 0, 0, $day, $month2num{$month}, $year);
		} 
		else {
			$year = $YEAR_NOW;
			$snapshotTime = timelocal(0, 0, 0, $day, $month2num{$month}, $year);
		}
		
		# Compute delta time
		my $timeDiff = $TIME_NOW - $snapshotTime;
		
		# If old => print
		if ( $timeDiff > ($OLDER_THAN_DAYS * 60 * 60 * 24) ) {
			# for friendly formatting
			$_ =~ s/\( /\(/g;
			print "$volumeName$_\n";
			$foundOlder += 1;
		}

	}
}

# at least one old snapshot found
if ( $foundOlder > 0 ) { 
	exit 0; 
}
else {
	exit 1;	
}
