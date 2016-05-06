#!/usr/bin/perl
use strict;
use warnings;

open I, "-|", "samtools-0.1.7 view -h $ARGV[0]";
open O, "|-", "samtools-0.1.7 view -Shb - >$ARGV[1]";

my $total = 0;
my $remain = 0;
while (<I>) {
	if (/^\@/) {
		if (/^\@HD/) {
			print O "\@HD\tVN:1.3\tSO:coordinate\n";
		} elsif (/^\@SQ/) {
			print O $_;
		} elsif (/^\@RG/) {
			next;
		} 
	} else {
		++$total;
		my @a = split /\t/;
		if (($a[1] == 83 or $a[1] == 99 or $a[1] == 147 or $a[1] == 163) and ($a[6] eq "=")) {
				++$remain;
				my @b = split / /, $a[0];
				shift @a;
				pop @a;
				print O "$b[0]\t", join("\t", @a), "\n";
		} else {
			next;
		}
	}
}
warn "$out\t", 1-$remain/$total, " filtered\n";
close I;
close O;
