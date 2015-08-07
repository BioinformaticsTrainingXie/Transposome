use 5.010;
use strict;
use warnings FATAL => 'all';
use Cwd;
use File::Spec;
use File::Basename;

use Test::More tests => 13;

BEGIN {
    use_ok('Transposome') || print "[Error]: Could not load Transposome.\n";
    use_ok('Transposome::SeqUtil')
      || print "[Error]: Could not load Transposome::SeqUtil.\n";
    use_ok('Transposome::SeqFactory')
      || print "[Error]: Could not load Transposome::SeqFactory.\n";
    use_ok('Transposome::Cluster')
      || print "[Error]: Could not load Transposome::Cluster.\n";
    use_ok('Transposome::Annotation')
      || print "[Error]: Could not load Transposome::Annotation.\n";
    use_ok('Transposome::PairFinder')
      || print "[Error]: Could not load Transposome::PairFinder.\n";
    use_ok('Transposome::Run::Blast')
      || print "[Error]: Could not load Transposome::Run::Blast.\n";
    use_ok('Transposome::Test::TestFixture')
	|| print "[Error]: Could not load Transposome::Test::TestFixture.\n";
}

diag("Testing Transposome $Transposome::VERSION, Perl $], $^X");

my $cwd = getcwd();
my $bin = File::Spec->catdir($cwd, 'bin');
local $ENV{PATH} = "$bin:$ENV{PATH}";

##See if we can load mgblast, formatdb, and blastall, which are required
my @path = split /:|;/, $ENV{PATH};

my ( $ex, $bl_seen, $mb_seen, $mg_seen, $fd_seen )  = ( 0, 0, 0, 0, 0 );
for my $p ( @path ) {
    my $bl = File::Spec->catfile($p, 'blastn');
    my $mb = File::Spec->catfile($p, 'makeblastdb');

    if ( -e $bl && -x $bl ) {
        next if $bl_seen;
        $ex++;
        ok( -e $bl && -x $bl, 'blastn exists and is executable' );
        $bl_seen = 1;
    }
    if ( -e $mb && -x $mb ) {
        next if $mb_seen;
        $ex++;
        ok( -e $mb && -x $mb, 'makeblastdb exists and is executable' );
        $mb_seen = 1;
    }


    my $mg = File::Spec->catfile($p, 'mgblast');
    my $fd = File::Spec->catfile($p, 'formatdb');

    if ( -e $mg && -x $mg ) {
        next if $mg_seen;
        $ex++;
        ok( -e $mg && -x $mg, 'mgblast exists and is executable' ); 
        $mg_seen = 1;
    }
    if ( -e $fd && -x $fd ) {
        next if $fd_seen;
        $ex++;
        ok( -e $fd && -x $fd, 'formatdb exists and is executable' );
        $fd_seen = 1;
    }
}

is( $ex, 4,
    'All required external programs for clustering and analysis exist and appear usable'
);

done_testing();
