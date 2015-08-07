#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Cwd;
use File::Find;
use File::Spec;
use File::Path          qw(remove_tree);
use Capture::Tiny       qw(capture);
use IPC::System::Simple qw(system);
use Transposome;

use aliased 'Transposome::Test::TestFixture';
use Test::More tests => 4;

my $program  = File::Spec->catfile('bin', 'transposome');
my $seqfile  = File::Spec->catfile('t', 'test_data', 't_reads.fas.gz');
my $repeatdb = File::Spec->catfile('t', 'test_data', 't_db.fas');
my $outdir   = File::Spec->catdir('t', 'test_transposome_cli_out');

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

my $cwd = getcwd();
my $bin = File::Spec->catdir($cwd, 'bin');

local $ENV{PATH} = "$bin:$ENV{PATH}";

my ($stdout, $stderr, @res) = capture { system([0..5], "perl -Iblib/lib $program --config $conf_file"); };

ok( -d $outdir, 'Output of Transposome created' );

# just check if the application completed without errors
for my $line (split /^/, $stderr) {
    chomp $line;
    if ($line =~ /Transposome completed at/) {
	like( $line, qr/Transposome completed at/, 
	      'Transposome CLI application completed successfully' );
    }
}

my @results;
find( sub { push @results, $File::Find::name if -f and /\.tgz$/ }, $outdir );
is( scalar(@results), 2, 'Output directories compressed successfully' );

remove_tree( $outdir, { safe => 1 } );
unlink $conf_file;
unlink glob "t/transposome_mgblast*";
unlink "formatdb.log";
