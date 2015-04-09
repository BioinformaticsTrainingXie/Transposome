package Transposome::Annotation::Mapping;

use 5.010;
use Moose::Role;
use Log::Any qw($log);

requires 'mk_key', 'map_family_name';

=head1 NAME

Transposome::Annotation::Mapping - Map BLAST hits to the full repeat taxonomy

=head1 VERSION

Version 0.09.4

=cut

our $VERSION = '0.09.4';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

    Consume this role in your class, or use Transposome::Annotation directly. E.g.,

    use Transposome::Annotation;

    my $cluster_file = '/path/to/cluster_file.cls';
    my $seqct        = 'total_seqs_in_analysis';    # Integer
    my $cls_tot      = 'total_reads_clustered';     # Integer

    my $annotation = Transposome::Annotation->new( database  => 'repeat_db.fas',
                                                   dir       => 'outdir',
                                                   file      => 'report.txt' );

    my $annotation_results =
        $annotation->annotate_clusters({ cluster_directory => $cls_dir_path,
                                         singletons_file => $singletons_file_path,
                                         total_sequence_num => $seqct,
                                         total_cluster_num => $cls_tot });
    
    $annotation->clusters_annotation_to_summary( $annotation_results );

=cut

=head1 METHODS

=head2 map_hit_family

 Title   : map_hit_family

 Usage   : my ($top_hit_superfamily, $cluster_annot) 
               = $self->map_hit_family($arr_ref, $anno_data);
           
 Function: Match only family name portion of the full TE identifier

                                                                            Return_type
 Returns : In order, 1) a reference to the top hit and superfamily          HashRef    
                     2) a reference to the cluster annotation               HashRef
            
                                                                            Arg_type
 Args    : In order, 1) reference to the repeat taxonomy for each element   ArrayRef
                     2) reference to the annotation data for a cluster      HashRef
                        
           An example of the hash for arg 2:

           { filebase     => $filebase,
             top_hit      => $top_hit,
             top_hit_frac => $top_hit_frac,
             class        => $class }

           An explanation of the values for the hash:
                                                                            Arg_type
           filebase - the cluster file basename                             Scalar
           top_hit  - the top BLAST hit for th the cluster                  Scalar
           top_hit_frac - the fraction of the cluster accounted             Scalar
                          for my the top_hit 
           class - the TE class of the top BLAST hit                        Scalar
=cut

sub map_hit_family {
    my $self = shift;
    my ($arr_ref, $anno_data) = @_;
    my (%top_hit_superfam, %cluster_annot);
    my ($filebase, $top_hit, $top_hit_frac, $readct, $class) 
        = @{$anno_data}{qw(filebase top_hit top_hit_frac readct class)};

    my $type = $self->_map_repeat_type($class);

    if ($class =~ /pseudogene|integrated_virus/) {
        my $anno_key = $self->mk_key($filebase,
				     $type,
				     $class,
				     '-',
				     '-',
				     $top_hit,
				     $top_hit_frac);

        $cluster_annot{$readct} = $anno_key;
        return (undef, \%cluster_annot);
    }
    else {
	for my $superfam_h (@$arr_ref) {
            for my $superfam (keys %$superfam_h) {
                for my $family (@{$superfam_h->{$superfam}}) {
                    if ($top_hit =~ /$family/) {
                        my $family_name = $self->map_family_name($family);
                        $top_hit_superfam{$top_hit} = $self->mk_key($family_name, $superfam);
                        my $anno_key = $self->mk_key($filebase, 
						     $type,
						     $class,
						     $superfam, 
						     $family_name, 
						     $top_hit, 
						     $top_hit_frac);
        
                        $cluster_annot{$readct} = $anno_key;
                    }
                }
            }
        }
        
        return (\%top_hit_superfam, \%cluster_annot);
    }
}

=head2 map_family_name

 Title   : map_family_name

 Usage   : my $family_name = $self->map_family_name($match);
           
 Function: Match only family name portion of the full TE identifier

                                                                            Return_type
 Returns : The TE family name                                               Scalar
            
                                                                            Arg_type
 Args    : The top BLAST hit for a cluster                                  Scalar

=cut

sub map_family_name {
    my $self = shift;
    my ($family) = @_;
    my $family_name;

    if ($family =~ /(^RL[GCX][_-][a-zA-Z]*\d*?[_-]?[a-zA-Z-]+?\d*?)/) {
        $family_name = $1;
    }
    elsif ($family =~ /(^D[HT][ACHMT][_-][a-zA-Z]*\d*?)/) {
        $family_name = $1;
    }
    elsif ($family =~ /(^PPP[_-][a-zA-Z]*\d*?)/) {
        $family_name = $1;
    }
    elsif ($family =~ /(^R[IS][LT][_-][a-zA-Z]*\d*?)/) {
        $family_name = $1;
    }
    else {
        $family_name = $family;
    }

    $family_name =~ s/_I// if $family_name =~ /_I_|_I$/;
    $family_name =~ s/_LTR// if $family_name =~ /_LTR_|_LTR$/;

    return $family_name;
}

=head2 _map_repeat_type

 Title   : _map_repeat_type

 Usage   : This is a private method, do not use it directly.
           
 Function: Return the repeat type given the TE order.
                                                                            Return_type
 Returns : The repeat type                                                  Scalar
            
                                                                            Arg_type
 Args    : The repeat order                                                 Scalar

=cut

sub _map_repeat_type {
    my $self = shift;
    my ($type) = @_;
    my %map = (
               'ltr_retrotransposon'     => 'transposable_element',
               'dna_transposon'          => 'transposable_element',
               'non-ltr_retrotransposon' => 'transposable_element',
               'endogenous_retrovirus'   => 'transposable_element',
               'Satellite'               => 'simple_repeat',
               );

    return $map{$type} if exists $map{$type};
    return $type if !exists $map{$type};
}

=head1 AUTHOR

S. Evan Staton, C<< <statonse at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests through the project site at 
L<https://github.com/sestaton/Transposome/issues>. I will be notified,
and there will be a record of the issue. Alternatively, I can also be 
reached at the email address listed above to resolve any questions.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Transposome::Annotation::Mapping


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013-2015 S. Evan Staton

This program is distributed under the MIT (X11) License, which should be distributed with the package. 
If not, it can be found here: L<http://www.opensource.org/licenses/mit-license.php>

=cut

1;
