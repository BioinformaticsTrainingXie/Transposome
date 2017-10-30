use 5.010;
use strict;
use warnings;
#use Data::Dump qw(dd); # for debugging, not required
use autodie qw(open);
use File::Spec;
use File::Temp;
use File::Path qw(remove_tree);
use Transposome::PairFinder;

use aliased 'Transposome::Test::TestFixture';
use Test::Most tests => 505;

my $seqfile  = File::Spec->catfile('t', 'test_data', 't_reads.fas.gz');
my $repeatdb = File::Spec->catfile('t', 'test_data', 't_db.fas');
my $outdir   = File::Spec->catdir('t', 'transposome_pairfinder_t');

my $tf_obj_keep = TestFixture->new(
    seq_file         => $seqfile,
    seq_format       => 'fasta',
    repeat_db        => $repeatdb,
    output_directory => $outdir,
    destroy          => 0,
    build_proper     => 1
);

my $keep_conf = $tf_obj_keep->config_constructor;
my ($keep_conf_file) = @$keep_conf;

my $test   = TestFixture->new( build_proper => 1, destroy => 0 );
ok( $test->blast_constructor, 'Can build proper mgblast data for testing' );
unlink glob("t/transposome_mgblast_*");

my $blast = $test->blast_constructor;
my ($blfl) = @$blast;

## test that object construction dies when given empty file
my $tmpbln = File::Temp->new(
                             TEMPLATE => "transposome_blast_XXXX",
                             DIR      => 't',
                             SUFFIX   => ".bln",
                             UNLINK   => 0
                             );

dies_ok { Transposome::Pairfinder->new( 
	config            => $keep_conf_file,
	file              => $tmpbln, 
	dir               => $outdir, 
	in_memory         => 1, 
	percent_identity  => 90, 
	fraction_coverage => 0.55,
	verbose           => 0 ); } 
'Transpsome::Pairfinder dies as expected when given empty input file';

unlink $tmpbln;

## test in-memory processing
my $mem_test = Transposome::PairFinder->new(
    config            => $keep_conf_file, 
    file              => $blfl,
    dir               => $outdir,
    in_memory         => 1,
    percent_identity  => 90.0,
    fraction_coverage => 0.55,
    verbose           => 0,
    log_to_screen     => 0,
);

ok( $mem_test->parse_blast, 'Can build in memory database and parse blast' );

my ( $mem_idx_file, $mem_int_file, $mem_hs_file ) = $mem_test->parse_blast;

ok( defined($mem_idx_file), 'Can parse blast to index in memory' );
ok( defined($mem_int_file), 'Can parse blast to integer file in memory ' );
ok( defined($mem_hs_file),  'Can parse blast to edge file in memory' );

my (
    $mem_idx_recct,  $mem_int_recct,  $mem_hs_recct,
    $file_idx_recct, $file_int_recct, $file_hs_recct
) = ( 0, 0, 0, 0, 0, 0 );
open my $mem_idx, '<', $mem_idx_file;
open my $mem_int, '<', $mem_int_file;
open my $mem_hs,  '<', $mem_hs_file;

while (<$mem_idx>) {
    chomp;
    my @f = split;
    is( scalar @f, 2, 'Index file has the right number of fields' );
    like( $f[1], qr/\d+/, 'Parsed score correctly for blast pairs' );

    #TODO: Test for unique pairs
    $mem_idx_recct++;
}
close $mem_idx;

is( $mem_idx_recct, 46, 'Correct number of unique pairs found in index' );

while (<$mem_int>) {
    chomp;
    my @f = split;
    is( scalar @f, 3,
        'Integer mapping of pairs has the right number of fields' );
    like( $f[0], qr/\d+/, 'Blast pairs mapped correctly to integer form' );
    like( $f[1], qr/\d+/, 'Blast pairs mapped correctly to integer form' );
    like( $f[2], qr/\d+/, 'Blast pairs mapped correctly to integer form' );

    #TODO: Test for unique pairs
    $mem_int_recct++;
}
close $mem_int;

is( $mem_int_recct, 25,
    'Correct number of unique pairs found in integer mapping' );

while (<$mem_hs>) {
    chomp;
    my @f = split;
    is( scalar @f, 3,
        'Integer mapping of pairs has the right number of fields' );
    like( $f[2], qr/\d+/, 'Blast pair score mapped parsed correctly' );

    #TODO: Test for unique pairs
    $mem_hs_recct++;
}
close $mem_hs;

is( $mem_hs_recct, 25, 'Correct number of unique pairs found in ID mapping' );
is( $mem_hs_recct, $mem_int_recct,
    'Index and integer mapping files contain the same records' );

my $test_dir = File::Spec->catdir('t', $outdir);
remove_tree($test_dir);

## test on-file processing
my $file_test = Transposome::PairFinder->new(
    config            => $keep_conf_file,
    file              => $blfl,
    dir               => $outdir,
    in_memory         => 0,
    percent_identity  => 90.0,
    fraction_coverage => 0.55,
    verbose           => 0,
    log_to_screen     => 0
);

ok( $file_test->parse_blast, 'Can build database on file and parse blast' );

my ( $onfile_idx_file, $onfile_int_file, $onfile_hs_file ) =
  $file_test->parse_blast;

ok( defined($onfile_idx_file), 'Can parse blast to index on file' );
ok( defined($onfile_int_file), 'Can parse blast to integer file on file' );
ok( defined($onfile_hs_file),  'Can parse blast to edge file on file' );

open my $file_idx, '<', $onfile_idx_file;
open my $file_int, '<', $onfile_int_file;
open my $file_hs,  '<', $onfile_hs_file;

while (<$file_idx>) {
    chomp;
    my @f = split;
    is( scalar @f, 2, 'Index file has the right number of fields' );
    like( $f[1], qr/\d+/, 'Parsed score correctly for blast pairs' );

    #TODO: Test for unique pairs
    $file_idx_recct++;
}
close $file_idx;

is( $file_idx_recct, 46, 'Correct number of unique pairs found in index' );

while (<$file_int>) {
    chomp;
    my @f = split;
    is( scalar @f, 3,
        'Integer mapping of pairs has the right number of fields' );
    like( $f[0], qr/\d+/, 'Blast pairs mapped correctly to integer form' );
    like( $f[1], qr/\d+/, 'Blast pairs mapped correctly to integer form' );
    like( $f[2], qr/\d+/, 'Blast pairs mapped correctly to integer form' );

    #TODO: Test for unique pairs
    $file_int_recct++;
}
close $file_int;

is( $file_int_recct, 25,
    'Correct number of unique pairs found in integer mapping' );

while (<$file_hs>) {
    chomp;
    my @f = split;
    is( scalar @f, 3,
        'Integer mapping of pairs has the right number of fields' );
    like( $f[2], qr/\d+/, 'Blast pair score mapped parsed correctly' );

    #TODO: Test for unique pairs
    $file_hs_recct++;
}
close $file_hs;

is( $file_hs_recct, 25, 'Correct number of unique pairs found in ID mapping' );
is( $file_hs_recct, $file_int_recct,
    'Index and integer mapping files contain the same records' );

## check both processing methods agree
is( $mem_idx_recct, $file_idx_recct,
    'In-memory and on-file processing methods generated the same index' );
is( $mem_int_recct, $file_int_recct,
    'In-memory and on-file processing methods generated the integer mapping files'
);
is( $mem_hs_recct, $file_hs_recct,
    'In-memory and on-file processing methods generated the same pair file with scores'
);

END {
    unlink $keep_conf_file;
    remove_tree($outdir, $blfl);
}

done_testing();
