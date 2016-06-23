#!/usr/bin/perl
use strict;
use warnings;

my @input = qw/
PVIP0012.chrx.Q50.fa.gz
PBEP0005.chrx.Q30.fa.gz
PBEP0009.chrx.Q30.fa.gz
PBEP0010.chrx.Q30.fa.gz
PBEP0023.chrx.Q30.fa.gz
PBEP0025.chrx.Q50.fa.gz
PBEP0028.chrx.Q30.fa.gz
PBEP0036.chrx.Q30.fa.gz
PBEP0039.chrx.Q30.fa.gz
PBEP0065.chrx.Q30.fa.gz
PBEP0067.chrx.Q30.fa.gz
PBEP0068.chrx.Q50.fa.gz
PBEP0069.chrx.Q30.fa.gz
/;

for (@input) {
	open my $in, "-|", "zcat $_";
	my $chr = <$in>;
	my $seq = <$in>;
	close $in;
	$seq =~ tr/RYMKSW/N/;
	s/.fa.gz$//;
	open my $out, "|-", "gzip -9c >$_.hetero_masked.fa.gz";
	print $out $chr, $seq;
	close $out;
}
