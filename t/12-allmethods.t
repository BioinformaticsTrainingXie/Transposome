#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Cwd;
use File::Spec;
use File::Path    qw(remove_tree);
use Module::Path  qw(module_path);
use Log::Log4perl qw(:easy);
use Transposome;
use Transposome::PairFinder;
use Transposome::Cluster;
use Transposome::SeqUtil;
use Transposome::Annotation;
use Transposome::Run::Blast;

use aliased 'Transposome::Test::TestFixture';
use Test::More tests => 34;

my $seqfile  = File::Spec->catfile('t', 'test_data', 't_reads.fas.gz');
my $repeatdb = File::Spec->catfile('t', 'test_data', 't_db.fas');

my $test = TestFixture->new(
    seq_file     => $seqfile,
    seq_format   => 'fasta',
    repeat_db    => $repeatdb,
    destroy      => 0,
    build_proper => 1
);

my $conf = $test->config_constructor;
my ($conf_file) = @$conf;

my $trans_obj = Transposome->new( config => $conf_file );
ok( $trans_obj->get_configuration, 'Configuration data loaded from file correctly' );
my $config = $trans_obj->get_configuration;

ok(
    defined( $config->{sequence_file} ),
    'Can set sequence data for configuration'
);
ok(
   defined( $config->{sequence_format} ),
    'Can set sequence format for configuration'
);
ok(
    defined( $config->{output_directory} ),
    'Can set ouput directory for configuration'
);
ok( defined( $config->{in_memory} ),
    'Can set memory conditions for configuration' );
is( $config->{in_memory}, 1,
    'Can correctly set memory conditions for analysis' );

ok(
    defined( $config->{percent_identity} ),
    'Can set percent identity for configuration'
);
ok(
    defined( $config->{fraction_coverage} ),
    'Can set fraction coverage for configuration'
);
ok(
    defined( $config->{merge_threshold} ),
    'Can set merge threshold for configuration'
);
is( $config->{percent_identity}, 90, 
    'Can correctly set percent identity for analysis' );
is( $config->{fraction_coverage}, 0.55, 
    'Can correctly set fraction coverage for analysis' );
is( $config->{merge_threshold}, 2, 
    'Can correctly set merge threshold for analysis' );

ok(
    defined( $config->{cluster_size} ),
    'Can set cluster size for configuration'
);
ok(
    defined( $config->{blast_evalue} ),
    'Can set blast evalue for configuration'
);
is( $config->{cluster_size}, 1, 
    'Can correctly set cluster size for analysis' );
is( $config->{blast_evalue}, 10,
    'Can correctly set blast evalue for analysis' );

ok(
    defined( $config->{repeat_database} ),
    'Can set repeat database for configuration'
);

ok( defined( $config->{run_log_file} ),
    'Can generate run log file for configuration' );
ok(
    defined( $config->{cluster_log_file} ),
    'Can generate cluster log file for configuration'
);

## init logger
#Log::Log4perl->easy_init( { file => ">>$config->{run_log_file}" } );
my $log_conf = qq{
    log4perl.category.Transposome       = INFO, Logfile

    log4perl.appender.Logfile           = Log::Log4perl::Appender::File
    log4perl.appender.Logfile.filename  = t/$config->{run_log_file}
    log4perl.appender.Logfile.layout    = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Logfile.layout.ConversionPattern = %m%n
  };

Log::Log4perl::init( \$log_conf );

my $cwd      = getcwd();
my $bin      = File::Spec->catdir($cwd, 'bin');
my $mgblast  = File::Spec->catfile($bin, 'mgblast');
my $formatdb = File::Spec->catfile($bin, 'formatdb');

my $blast = Transposome::Run::Blast->new(
    file          => $config->{sequence_file},
    format        => $config->{sequence_format},
    dir           => $config->{output_directory},
    threads       => 1,
    cpus          => 1,
    seq_num       => $config->{sequence_num},
    mgblast_exec  => $mgblast,
    formatdb_exec => $formatdb
);

my $blastdb = $blast->run_allvall_blast;
ok( defined($blastdb), 'Can run all vs. all blast correctly' );

my $blast_res = Transposome::PairFinder->new(
    file              => $blastdb,
    dir               => $config->{output_directory},
    in_memory         => $config->{in_memory},
    percent_identity  => $config->{percent_identity},
    fraction_coverage => $config->{fraction_coverage}
);

my ( $idx_file, $int_file, $hs_file ) = $blast_res->parse_blast;
ok( defined($idx_file), 'Can parse all vs. all blast correctly' );
ok( defined($int_file), 'Can parse all vs. all blast correctly' );
ok( defined($hs_file),  'Can parse all vs. all blast correctly' );

my $path    = module_path("Transposome::Cluster");
my $file    = Path::Class::File->new($path);
my $pdir    = $file->dir;
my $bdir    = Path::Class::Dir->new("$pdir/../../bin");
my $realbin = $bdir->resolve;

my $cluster = Transposome::Cluster->new(
    file            => $int_file,
    dir             => $config->{output_directory},
    merge_threshold => $config->{merge_threshold},
    cluster_size    => $config->{cluster_size},
    bin_dir         => $realbin
);

my $comm = $cluster->louvain_method;
ok( defined($comm), 'Can successfully perform clustering' );

my $cluster_file = $cluster->make_clusters( $comm, $idx_file );
ok( defined($cluster_file),
    'Can successfully make communities following clusters' );

my ( $read_pairs, $vertex, $uf ) =
  $cluster->find_pairs( $cluster_file, $config->{cluster_log_file} );
ok( defined($read_pairs), 'Can find split paired reads for merging clusters' );

my $memstore = Transposome::SeqUtil->new(
    file      => $config->{sequence_file},
    in_memory => $config->{in_memory}
);

my ( $seqs, $seqct ) = $memstore->store_seq;
is( $seqct, 70, 'Correct number of sequences stored' );
ok( ref($seqs) eq 'HASH', 'Correct data structure for sequence store' );

my $cluster_data =
  $cluster->merge_clusters({ graph_vertices         => $vertex,
                             sequence_hash          => $seqs,
                             read_pairs             => $read_pairs,
                             cluster_log_file       => $config->{cluster_log_file},
                             graph_unionfind_object => $uf });

$cluster_data->{total_sequence_num} = $seqct;
ok( defined($cluster_data->{cluster_directory}),
    'Can successfully merge communities based on paired-end information' );
is( $cluster_data->{total_cluster_num}, 48, 'The expected number of reads went into clusters' );

my $annotation = Transposome::Annotation->new(
    database => $config->{repeat_database},
    dir      => $config->{output_directory},
    file     => $config->{cluster_log_file},
    threads  => 1,
    cpus     => 1
);

my $annotation_results = $annotation->annotate_clusters( $cluster_data );

is( $annotation_results->{total_sequence_num}, 48,       'Correct number of reads annotated' );
is( $annotation_results->{total_sequence_num}, $cluster_data->{total_cluster_num}, 
'Same number of reads clustered and annotated' );

ok( ref($annotation_results->{cluster_blast_reports}) eq 'ARRAY',
    'Correct data structure returned for creating annotation summary (1)' );
ok( ref($annotation_results->{cluster_superfamilies}) eq 'ARRAY',
    'Correct data structure returned for creating annotation summary (2)' );

$annotation->clusters_annotation_to_summary( $annotation_results );

unlink glob("t/transposome_mgblast*");
unlink glob("t_rep*");
remove_tree( $config->{output_directory}, { safe => 1 } );
unlink "t/$config->{run_log_file}";
unlink $conf_file;
