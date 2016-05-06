#!/usr/bin/perl
use strict;
use warnings;

open I, "<", "/share/users/miaolin/6.Pbe_genomics/2.round2_201511-201604/reference/felCat8_mfa_masked.fa";
open CPG, "-|", "zcat /bak/seqdata/genomes/Felis_catus_80_masked/UCSC_genome_annotation/cpgIslandExtUnmasked.txt.gz"; # Last modified on 21-Dec-2015
open GENE, "-|", "zcat /bak/seqdata/genomes/Felis_catus_80_masked/UCSC_genome_annotation/refGene.txt.gz /bak/seqdata/genomes/Felis_catus_80_masked/UCSC_genome_annotation/xenoRefGene.txt.gz"; # Last modified on 14-Feb-2016 21-Feb-2016
open O1, ">", "felCat8_gene_masked_auto.fa";
open O2, ">", "felCat8_gene_masked_chrx.fa";

my %chr;
while (<I>) {
	chomp;
	s/>//;
	my $seq = <I>;
	chomp $seq;
	$chr{$_} = $seq;
}
close I;
warn "Read sequences complete!\n";

while (<CPG>) {
	my @a = split /\t/;
	next unless grep(/^$a[1]$/, keys %chr);
	warn $_ if $a[2] >= $a[3];
	warn $_ if $a[3] > length $chr{$a[1]};
	my $l = $a[3] - $a[2] + 1;
	substr $chr{$a[1]}, $a[2], $l, "N" x $l;
}
close CPG;
warn "Mask CpG complete!\n";

while (<GENE>) {
	my @a = split /\t/;
	next unless grep(/^$a[2]$/, keys %chr);
	my @sta = split /,/, $a[9]; # Starts of exons
	my @end = split /,/, $a[10]; # Ends of exons
	warn $_ if @sta != @end;
	foreach (0 .. @sta-1) {
		warn $_ if $sta[$_] >= $end[$_];
		warn $_ if $end[$_] > length $chr{$a[2]};
		my $s = $sta[$_] - 1000; # Start of mask
		$s = 0 if $s < 0;
		my $e = $end[$_] + 1000; # End of mask
		$e = (length $chr{$a[2]}) - 1 if $e > (length $chr{$a[2]}) - 1;
		my $l = $e - $s + 1;
		substr $chr{$a[2]}, $s, $l, "N" x $l;
	}
}
close GENE;
warn "Mask GENE complete!\n";

foreach (sort keys %chr) {
	if (/chr\w\d/) {
		print O1 ">$_\n$chr{$_}\n";
	} elsif (/chrX/) {
		print O2 ">$_\n$chr{$_}\n";
	} else {
		next;
	}
}
close O1;
close O2;
warn "Done!\n";
