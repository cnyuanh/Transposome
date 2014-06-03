package Transposome::SeqIO;

use 5.012;
use Moose;
use Method::Signatures;
use namespace::autoclean;

with 'MooseX::Log::Log4perl',
     'Transposome::Role::File';

=head1 NAME

Transposome::SeqIO - Class for reading Fasta/q data.

=head1 VERSION

Version 0.07.3

=cut

our $VERSION = '0.07.3';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

    use Transposome::SeqIO;

    my $trans_obj = Transposome::SeqIO->new( file => $infile );

    while (my $seq = $trans_obj->next_seq) {
         # do something interesting with $seq
    }

=cut

has 'id' => (
    is        => 'rw',
    isa       => 'Str',
    reader    => 'get_id',
    writer    => 'set_id',
    predicate => 'has_id',
);

has 'seq' => (
    is        => 'rw',
    isa       => 'Str',
    reader    => 'get_seq',
    writer    => 'set_seq',
    predicate => 'has_seq',
);

has 'qual' => (
    is        => 'rw',
    lazy      => 1,
    default   => undef,
    reader    => 'get_qual',
    writer    => 'set_qual',
    predicate => 'has_qual',
);

=head1 METHODS

=head2 next_seq

 Title   : next_seq
 Usage   : while (my $seq = $trans_obj->next_seq) { ... };
           
 Function: Reads fasta/fastq files seamlessly without needing to 
           specify the format.
                                                                            
 Returns : A Transposome::SeqIO object on which you can call methods                  
           representing the sequence, id, or quality scores (in the
           case of fastq). E.g.,
           
           while (my $seq = $trans_obj->next_seq) { 
               $seq->get_id;   # gets the sequence id
               $seq->get_seq;  # gets the sequence
               $seq->get_qual; # gets the quality scores
           }

           Each of the above methods an easy way of checking to see
           if that slot is set. E.g.,
           
           if ($seq->has_id)   { ... # is the id set? }
           if ($seq->has_seq)  { ... # is the seq set? }
           if ($seq->has_qual) { ... # is the qual set? This will be no for Fasta. }

 Args    : Takes a file handle. You can get the file handle                 
           by calling the method 'get_fh' on a Transposome::SeqIO object. E.g.,
 
           my $trans_obj = Transposome::SeqIO->new( file => $infile );

=cut

method next_seq {
    my $fh   = $self->fh;
    my $line = $fh->getline;
    return unless defined $line && $line =~ /\S/;
    chomp $line;

    if (substr($line, 0, 1) eq '>') {
	# this method checks if the Casava format is 1.4 or 1.8+
        my $name = $self->_set_id_per_encoding($line);
        $self->set_id($name);
        
        my ($sline, $seq);
        while ($sline = <$fh>) {
            chomp $sline;
            last if $sline =~ />/;
            $seq .= $sline;
        }
        seek $fh, -length($sline)-1, 1 if length $sline;

        if (!length($seq)) {
            $self->log->error("No sequence for Fasta record '$name'.")
		if Log::Log4perl::initialized();
	    exit(1);
        }
        $self->set_seq($seq);
        return $self;
    }
    elsif (substr($line, 0, 1) eq '@') {
        my $name = $self->_set_id_per_encoding($line);
        $self->set_id($name);

        my ($sline, $seq);
        while ($sline = <$fh>) {
            chomp $sline;
            last if $sline =~ /^\+/;
            $seq .= $sline;
        }
        seek $fh, -length($sline)-1, 1 if length $sline;

        if (!length($seq)) {
	    $self->log->error("No sequence for Fastq record '$name'.")
		if Log::Log4perl::initialized();
	    exit(1);
        }
        $self->set_seq($seq);
        
        my $cline = <$fh>;
        chomp $cline;
        unless (substr($cline, 0, 1) =~ /^\+/) {
	    $self->log->error("No comment line for Fastq record '$name'.")
		if Log::Log4perl::initialized();
	    exit(1);
        }
        my $qual;
        while (my $qline = <$fh>) {
            chomp $qline;
            $qual .= $qline;
            last if length($qual) >= length($seq);
        }
   
        if (!length($qual)) {
            $self->log->error("No quality scores for '$name'.")
		if Log::Log4perl::initialized();
	    exit(1);
        }

        unless (length($qual) >= length($seq)) {
	    $self->log->error("Unequal number of quality and scores and bases for '$name'.")
		if Log::Log4perl::initialized();
	    exit(1);
        }
        $self->set_qual($qual);

        return $self;
    }
    else {
	$self->log->error("'$line' does not look like Fasta or Fastq.")
	    if Log::Log4perl::initialized();
	exit(1);
    }
}


=head2 _set_id_per_encoding

Title   : _set_id_per_encoding

Usage   : This is a private method, do not use it directly.
          
Function: Try to determine format of sequence files
          and preserve paired-end information.
                                                               Return_type
Returns : A corrected sequence header if Illumina              Scalar
          Illumina 1.8+ is detected                           
        
                                                               Arg_type
Args    : A sequence header                                    Scalar

=cut

method _set_id_per_encoding ($hline) {
    if ($hline =~ /^.?(\S+)\s(\d)\S+/) {
	return $1."/".$2;
    }
    elsif ($hline =~ /^.?(\S+)/) {
	return $1;
    }
    else {
	return '';
    }
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

    perldoc Transposome::SeqIO


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013-2014 S. Evan Staton

This program is distributed under the MIT (X11) License, which should be distributed with the package. 
If not, it can be found here: L<http://www.opensource.org/licenses/mit-license.php>

=cut

__PACKAGE__->meta->make_immutable;

1;
