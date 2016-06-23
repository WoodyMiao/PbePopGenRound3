#!/usr/bin/perl
use strict;
use warnings;

open I, "<", "/share/users/miaolin/6.Pbe_genomics/2.round2_201511-201604/reference/felCat8_mfa_masked.fa";
open GENE, "-|", "zcat /bak/seqdata/genomes/Felis_catus_80_masked/UCSC_genome_annotation/refGene.txt.gz /bak/seqdata/genomes/Felis_catus_80_masked/UCSC_genome_annotation/xenoRefGene.txt.gz"; # Last modified on 05-Jun-2016 19-Jun-2016
open O1, ">", "felCat8_cds_unmasked_auto.fa";
open O2, ">", "felCat8_cds_unmasked_chrx.fa";

my %chrall;
my %chrcds;
while (<I>) {
	chomp;
	s/>//;
	my $seq = <I>;
	chomp $seq;
	$chrall{$_} = $seq;
	my $l = length $seq;
	$chrcds{$_} = "N" x $l;
}
close I;
warn "Read sequences complete!\n";

while (<GENE>) {
	my @a = split /\t/;
	next unless grep(/^$a[2]$/, keys %chrall);
	my @sta = split /,/, $a[9]; # Starts of exons
	my @end = split /,/, $a[10]; # Ends of exons
	warn $_ if @sta != @end;
	foreach (0 .. @sta-1) {
		$sta[$_] = $a[6] if $sta[$_] < $a[6];
		$end[$_] = $a[7] if $end[$_] > $a[7];
		next if $end[$_] < $sta[$_];
		my $l = $end[$_] - $sta[$_] + 1;
		substr $chrcds{$a[2]}, $sta[$_], $l, substr($chrall{$a[2]}, $sta[$_], $l);
	}
}
close GENE;
warn "Pick CDS complete!\n";

foreach (sort keys %chrcds) {
	if (/chr\w\d/) {
		print O1 ">$_\n$chrcds{$_}\n";
	} elsif (/chrX/) {
		print O2 ">$_\n$chrcds{$_}\n";
	} else {
		next;
	}
}
close O1;
close O2;
warn "Done!\n";
