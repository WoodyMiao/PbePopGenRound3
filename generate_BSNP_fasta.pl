#!/usr/bin/perl

use strict;
use warnings;

die "This program generate fasta using reference and BSNP output.\nAuther: Woody
Usage: $0 <reference.fa> <SNP.gz> <nSNP> <output.fa.gz> <autosome mean coverage> <1=male|2=female> <A=autosome|X=chrX> <minimum Phred quality>\n" if @ARGV < 8;

open REF, "<", $ARGV[0];
open SNP, "-|", "zcat $ARGV[1]";
open NSN, "<", $ARGV[2];
open OUT, "|-", "gzip -9c >$ARGV[3]";
my $maxc = $ARGV[4] * 1.5; # Max coverage
my $minc = $ARGV[4] * 0.5; # Min coverage
my $pSNP = 1 - 10**(-$ARGV[7]/10); # Min SNP posterior probability 
my $pNSN = $ARGV[7]/2 + 33; # Min ASCII value of ProbSNP in nSNP file 

my %ref;
my %len;
while (<REF>) {
	chomp;
	s/>//;
	my $seq = <REF>;
	chomp $seq;
	$ref{$_} = $seq;
	$len{$_} = length $seq;
}
close REF;

my %out;
foreach (keys %ref) {
       $out{$_} = "N" x $len{$_};
}       

<SNP>;
while (<SNP>) {
	next if /^chrMT/;
	if ($ARGV[6] eq "A") {
		next if /^chrX/;
	} elsif ($ARGV[6] eq "X") {
		next if /^chr\w\d/;
	} else {
		die "Chromosome code error!\n";
	}
	my @a = split /\t/;
	if ($a[1] >= $len{$a[0]}) {
		warn "$ARGV[1] $a[0] $a[1] >= $len{$a[0]}\n";
		next;
	}
	next if substr($ref{$a[0]}, $a[1], 1) eq "N";
	if ($ARGV[5] == 1) {
		if ($a[0] eq "chrX") {
			next if ($a[30] < $minc/2) or ($a[30] > $maxc/2);
		} else {
			next if ($a[30] < $minc) or ($a[30] > $maxc);
		}
	} elsif ($ARGV[5] == 2) {
		next if ($a[30] < $minc) or ($a[30] > $maxc);
	} else {
		die "Sex code error!\n";
	}
#	my @rq = split //, $a[-2]; # Read Quality Scores
#	my @aq = split //, $a[-1]; # Align Quality Scores
#	my $nr = @rq; # Number of Reads
#	my $ec; # Effective Coverage
#	foreach (0 .. $nr-1) {
#		my $rq = ord($rq[$_]) - 33;
#		my $aq = ord($aq[$_]) - 33;
#		my $c = (1 - (10**(-$rq/10))) * (1 - (10**(-$aq/10)));
#		$ec += $c;
#	}
#	next if $ec < 5;
	foreach (9 .. 18) {
		if ($a[$_] > $pSNP) {
       			substr $out{$a[0]}, $a[1], 1, $a[4];
			last;
		}
	}
}
close SNP;
#warn "Read $ARGV[1] complete!\n";

<NSN>;
while (<NSN>) {
	next if /^chrMT/;
	if ($ARGV[6] eq "A") {
		next if /^chrX/;
	} elsif ($ARGV[6] eq "X") {
		next if /^chr\w\d/;
	} else {
		die "Chromosome code error!\n";
	}
	my @a = split / +/;
	my @b = split //, $a[4];
	my @c = split //, $a[3];
	foreach (0 .. $a[2]-1) {
		my $cover = ord($c[$_]) - 33;
		if ($ARGV[5] == 1) {
			if ($a[0] eq "chrX") {
				next if ($cover < $minc/2) or ($cover > $maxc/2);
			} else {
				next if ($cover < $minc) or ($cover > $maxc);
			}
		} elsif ($ARGV[5] == 2) {
			next if ($cover < $minc) or ($cover > $maxc);
		} else {
			die "Sex code error!\n";
		}
		if (ord($b[$_]) > $pNSN) {
			my $coor = $a[1] + $_; # 0 based coordinate
			if ($coor >= $len{$a[0]}) {
				warn "$ARGV[2] $a[0] $coor >= $len{$a[0]}\n";
				next;
			}
			substr $out{$a[0]}, $coor, 1, substr($ref{$a[0]}, $coor, 1);
		}
	}
}
close NSN;
#warn "Read $ARGV[2] complete!\n";

print OUT ">$_\n$out{$_}\n" foreach sort keys %out;
close OUT;
warn "Write $ARGV[3] complete!\n";
