use strict;
use warnings;

use aliased 'Transposome::Test::TestFixture';
use Test::More tests => 1;

my $test = TestFixture->new( build_proper => 1, destroy => 1 );
ok( $test->blast_constructor, 'Can build proper megablast data for testing' );

done_testing();
