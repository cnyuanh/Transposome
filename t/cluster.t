#!/usr/bin/env perl

use 5.012;
use strict;
use warnings;
use File::Spec;
use File::Basename;
use File::Path qw(make_path);
use Data::Dump qw(dd);
use PairFinder;
use TestUtils;
use Cluster;
use SeqStore;

use Test::More tests => 6;

my $infile = 'Phoeb_330164_interl.fasta';
my $outdir = 'pairfinder_t';
my $report = 'cluster_test_rep.txt';
my $test = TestUtils->new( build_proper => 1, destroy => 0 );
my $blast = $test->blast_constructor;
my ($blfl) = @$blast;

my $blast_res = PairFinder->new( file              => $blfl,  
				 dir               => $outdir,                                                                              
				 in_memory         => 1,                                                                                              
				 percent_identity  => 90.0,                                                                                           
				 fraction_coverage => 0.55 );


my ($idx_file, $int_file, $hs_file) = $blast_res->parse_blast;

my $cluster = Cluster->new( file            => $int_file,
                            dir             => $outdir,
                            merge_threshold => 2,
                            cluster_size    => 1);

ok( $cluster->louvain_method, 'Can perform clustering with Louvain method' );

diag("\nTrying Louvain clustering now, this may take a couple of seconds...\n");
my $comm = $cluster->louvain_method;
ok( defined($comm), 'Can successfully perform clustering' );

my $cluster_file = $cluster->make_clusters($comm, $idx_file);
ok( defined($cluster_file), 'Can successfully make communities following clusters' );

my ($read_pairs, $vertex, $uf) = $cluster->find_pairs($cluster_file, $report);
ok( defined($read_pairs), 'Can find split paired reads for merging clusters' );

diag("\nIndexing sequences, this will take a few seconds...\n");
my $memstore = SeqStore->new( file => $infile, in_memory => 1 );
my ($seqs, $seqct) = $memstore->store_seq;

diag("\nTrying to merge clusters...\n");

my ($cls_dir_path, $cls_with_merges_path, $cls_tot) = $cluster->merge_clusters($vertex, $seqs, 
                                                                               $read_pairs, $report, $uf);

ok( defined($cls_dir_path), 'Can successfully merge communities based on paired-end information' );
ok( $cls_tot == 46, 'The expected number of reads went into clusters' );

system("rm -rf $outdir $blfl");