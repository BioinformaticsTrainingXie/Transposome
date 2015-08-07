use 5.010;
use strict;
use warnings;
use Transposome::SeqUtil;
use Transposome::SeqFactory;

use aliased 'Transposome::Test::TestFixture';
use Test::More tests => 48;

my $test   = TestFixture->new( build_proper => 1, destroy => 0 );
my $fa_arr = $test->fasta_constructor;
my $fq_arr = $test->fastq_constructor;

for my $fa ( @$fa_arr ) {
    my $seqio = Transposome::SeqFactory->new( file => $fa )->make_seqio_object;
    while ( my $seq = $seqio->next_seq ) {
        if ( $seq->has_id && $seq->has_seq && !$seq->has_qual ) {
            my $memstore =
              Transposome::SeqUtil->new( file => $fa, in_memory => 1 );
            {
                my ( $seqs, $seqct ) = $memstore->store_seq;
                is( $seqct, 6,
                    'There are exactly six Fasta sequences being stored in memory'
                );
                my $idct = scalar( keys %$seqs );
                is( $seqct, $idct,
                    'The same number of Fasta sequences were read and stored in memory'
                );
            }
            my $diskstore =
              Transposome::SeqUtil->new( file => $fa, in_memory => 0 );
            {
                my ( $seqs, $seqct, $seq_dbm ) = $diskstore->store_seq;
                is( $seqct, 6,
                    'There are exactly six Fasta sequences being stored on file'
                );
                my $idct = scalar( keys %$seqs );
                is( $seqct, $idct,
                    'The same number of Fasta sequences were read and stored on file'
                );
		untie %$seqs;
		unlink $seq_dbm;
            }
        }
    }
    unlink $fa;
}

for my $fq ( @$fq_arr ) {
    my $seqio = Transposome::SeqFactory->new( file => $fq, format => 'fastq' )->make_seqio_object;
    while ( my $seq = $seqio->next_seq ) {
        if ( $seq->has_id && $seq->has_seq && $seq->has_qual ) {
            my $memstore =
              Transposome::SeqUtil->new( file => $fq, in_memory => 1, format => 'fastq' );
            {
                my ( $seqs, $seqct ) = $memstore->store_seq;
                is( $seqct, 6,
                    'There are exactly six Fastq sequences being stored in memory'
                );
                my $idct = scalar( keys %$seqs );
                is( $seqct, $idct,
                    'The same number of Fastq sequences were read and stored in memory'
                );
            }
            my $diskstore =
              Transposome::SeqUtil->new( file => $fq, in_memory => 0, format => 'fastq' );
            {
                my ( $seqs, $seqct, $seq_dbm ) = $diskstore->store_seq;
                is( $seqct, 6,
                    'There are exactly six Fastq sequences being stored on file'
                );
                my $idct = scalar( keys %$seqs );
                is( $seqct, $idct,
                    'The same number of Fastq sequences were read and stored on file'
                );
		untie %$seqs;
		unlink $seq_dbm;
            }
        }
    }
    unlink $fq;
}

done_testing();
