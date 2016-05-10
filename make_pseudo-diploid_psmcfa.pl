#!/usr/bin/perl
use strict;
use warnings;

die "This program generates pseudo-diploid psmcfa file using two gzipped haploid fasta.\nAuther: Woody
Usage: $0 <input1.fa.gz> <input2.fa.gz> <output.psmcfa>\n" if @ARGV < 3;

open I1, "-|", "gzip -dc $ARGV[0]";
open I2, "-|", "gzip -dc $ARGV[1]";
open O, ">", "$ARGV[2]";

my $mis;
my $sub;
my $dot;
my $one;
my $o;
while (<I1>) {
	print O $_;
	my $seq1 = <I1>;
	chomp $seq1;
	my $len = length $seq1;
	<I2>;
	my $seq2 = <I2>;
	chomp $seq2;
	die "Error: $ARGV[0] and $ARGV[1] have different length!\n" if length $seq2 != $len;
	my $t;
	for (my $i=0; $i < $len; $i += 100) {
		my $u1 = substr $seq1, $i, 100;
		last if length($u1) < 100;
		my $u2 = substr $seq2, $i, 100;
		my $M = 0;
		my $S = 0;
		foreach my $j (0 .. 99) {
			my $v1 = substr($u1, $j, 1);
			my $v2 = substr($u2, $j, 1);
			die "Error: $ARGV[0] is not haploid!\n" unless $v1 =~ /[ACGTN]/;
			die "Error: $ARGV[1] is not haploid!\n" unless $v2 =~ /[ACGTN]/;
			if ($v1 eq "N" or $v2 eq "N") {
				++$M;
			} else {
				++$S if $v1 ne $v2;
			}
		}
		$mis += $M;
		$sub += $S;
		if ($M >= 90) {
			print O ".";
			++$dot;
		} elsif ($S) {
			print O "1";
			++$one;
		} else {
			print O "0";
			++$o;
		}
		++$t;
		if ($t == 100) {
			print O "\n";
			$t = 0;
		}
	}
}
close I1;
close I2;
close O;
warn "$ARGV[0]\t$ARGV[1]\t$mis\t$sub\t$ARGV[2]\t$dot\t$one\t$o\n";
