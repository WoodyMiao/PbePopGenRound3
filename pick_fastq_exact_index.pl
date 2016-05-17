#!/usr/bin/perl
use strict;
use warnings;
use threads;

my %input = (
"PBEP0025", "/bak/archive/projects/LeopardCat/1.raw_fastq/HiSeq2000/PBE084_lane1_1.fq.gz /bak/archive/projects/LeopardCat/1.raw_fastq/HiSeq2000/PBE084_lane2_1.fq.gz /bak/archive/projects/LeopardCat/1.raw_fastq/HiSeq2000/PBE084_lane3_1.fq.gz /bak/archive/projects/LeopardCat/1.raw_fastq/HiSeq2000/PBE084_lane4_1.fq.gz /bak/archive/projects/LeopardCat/1.raw_fastq/HiSeq2000/PBE084_lane6_1.fq.gz /bak/archive/projects/LeopardCat/1.raw_fastq/HiSeq2000/PBE084_lane7_1.fq.gz",
"PBEP0068", "/bak/archive/projects/LeopardCat/1.raw_fastq/HiSeq2000/PBE144_lane1_1.fq.gz /bak/archive/projects/LeopardCat/1.raw_fastq/HiSeq2000/PBE144_lane2_1.fq.gz /bak/archive/projects/LeopardCat/1.raw_fastq/HiSeq2000/PBE144_lane3_1.fq.gz /bak/archive/projects/LeopardCat/1.raw_fastq/HiSeq2000/PBE144_lane4_1.fq.gz /bak/archive/projects/LeopardCat/1.raw_fastq/HiSeq2000/PBE144_lane6_1.fq.gz",
"PVIP0012", "/bak/archive/projects/LeopardCat/1.raw_fastq/HiSeq2000/PVI033_lane1_1.fq.gz /bak/archive/projects/LeopardCat/1.raw_fastq/HiSeq2000/PVI033_lane2_1.fq.gz /bak/archive/projects/LeopardCat/1.raw_fastq/HiSeq2000/PVI033_lane3_1.fq.gz /bak/archive/projects/LeopardCat/1.raw_fastq/HiSeq2000/PVI033_lane4_1.fq.gz /bak/archive/projects/LeopardCat/1.raw_fastq/HiSeq2000/PVI033_lane6_1.fq.gz /bak/archive/projects/LeopardCat/1.raw_fastq/HiSeq2000/PVI033_lane7_1.fq.gz");
my %index = qw/ PBEP0025 GTTTCG PBEP0068 CGTACG PVIP0012 GAGTGG /;
my %thread;
for (sort keys %input) {
	$thread{$_} = threads->new(\&pick_index, ($_, $input{$_}));
}

for (sort keys %thread) {
	my $j = $thread{$_}->join;
	warn "$_: ${$j}[0] pairs of reads picked out of ${$j}[1].\n";
}

sub pick_index {
	my ($id, $files) = @_;
	open my $o1, "|-", "gzip -9c >${id}_$index{$id}_1.fq.gz";
	open my $o2, "|-", "gzip -9c >${id}_$index{$id}_2.fq.gz";
	my $picked;
	my $total;
	my @list = split / /, $files;
	for (@list) {
		open my $i1, "-|", "zcat $_";
		s/1.fq.gz$//;
		warn "Reading $_ read pairs ...\n";
		open my $i2, "-|", "zcat ${_}2.fq.gz";
		while (<$i1>) {
			my $i1l2 = <$i1>;
			my $i1l3 = <$i1>;
			my $i1l4 = <$i1>;
			chomp;
			my @c1 = split / /;
			my $index1 = (split /:/, $c1[1])[3];
			my $d = <$i2>;
			my $i2l2 = <$i2>;
			my $i2l3 = <$i2>;
			my $i2l4 = <$i2>;
			chomp $d;
			my @c2 = split / /, $d;
			my $index2 = (split /:/, $c2[1])[3];
			if ($c1[0] eq $c2[0] and $index1 eq $index2) {
				if ($index1 eq $index{$id}) {
					print $o1 "$_\n", $i1l2, $i1l3, $i1l4;
					print $o2 "$d\n", $i2l2, $i2l3, $i2l4;
					++$picked;
				}
			} else {
				warn $id;
			}
			++$total
		}
		close $i1;
		close $i2;
	}
	close $o1;
	close $o2;
	return [$picked, $total];
}
