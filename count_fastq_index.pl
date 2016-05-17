#!/usr/bin/perl
use strict;
use warnings;
use threads;
use File::Basename;

my %thread;
open I, "<", "list.txt";
while (<I>) {
	chomp;
	my $i = basename $_;
	$i =~ s/_1.fq.gz$//;
	$thread{$i} = threads->new(\&count_index, $_);
}
close I;

open O, ">", "count_fastq_index.txt";
print O "File\t#Reads\tIndex\t#Count\tRatio\tIndex\t#Count\tRatio\t...\n";
for (sort keys %thread) {
	my $j = $thread{$_}->join;
	print O "${_}_1.fq.gz\t${$j}{t}";
	for (sort {${$j}{$b} <=> ${$j}{$a}} keys %{$j}) {
		next if $_ eq "t";
		my $r = sprintf("%.4f", ${$j}{$_} / ${$j}{t});
		print O "\t$_\t${$j}{$_}\t$r";
	}
	print O "\n";
}
close O;

sub count_index {
	my $in = shift;
	open my $i1, "-|", "zcat $in";
	$in =~ s/1.fq.gz$//;
	open my $i2, "-|", "zcat ${in}2.fq.gz";
	my %index;
	my $total;
	while (<$i1>) {
		++$total;
		chomp;
		my @c = split / /;
		my $index1 = (split /:/, $c[1])[3];
		my $d = <$i2>;
		chomp $d;
		@c = split / /, $d;
		my $index2 = (split /:/, $c[1])[3];
		if ($index1 eq $index2) {
			++$index{$index1};
		} else {
			warn $in;
		}
		<$i1>; <$i1>; <$i1>;
		<$i2>; <$i2>; <$i2>;
	}
	$index{t} = $total;
	return \%index;
}
