package Git::Repository::Log::Queue::Iterator;

use strict;
use warnings;
use 5.006;
use Carp;

use File::Spec::Functions qw/ catdir /;
use Git::Repository qw( Log );
use Scalar::Util qw( blessed );


sub new {
  my $class = shift;
  my @cmd;
  my @r;
  if (ref $_[0] eq 'ARRAY') {
    my $gitdirs = shift;
    for (@$gitdirs) {
      if (ref $_ && $_->isa('Git::Repository')) {
        push @r, $_;
      } else {
        push @r, Git::Repository->new(git_dir => $_);
      }
    }
  } else {
    while (@_) {
      local $_ = shift;
      if (ref $_ && $_->isa('Git::Repository')) {
        push @r, $_;
      } elsif (/^--$/) {
        push @cmd, $_, @_;
        last;
      } elsif (/^--git-dir=(.*)$/) {
        my $r = eval { Git::Repository->new(git_dir => $_) };
        if ($r) {
          push @r, $r;
        } else {
          push @cmd, $_;
        }
      } elsif (-d $_) {
        my $r = eval { Git::Repository->new(git_dir => $_) } ||
          eval { Git::Repository->new(git_dir => catdir($_, '.git')) };
        if ($r) {
          push @r, $r;
        } else {
          push @cmd, $_;
        }
      } else {
        push @cmd, $_;
      }
    }
  }
  my @queue;
  for (@r) {
    my $iterator = $_->log(@cmd);
    push @queue, { iterator => $iterator, r => $_ };
  }
  my $reverse = grep { $_ eq '--reverse' } @cmd;
  bless { queue => \@queue, reverse => $reverse }, $class;
}


sub next {
  my ($self) = @_;

  my $queue = $self->{queue};
  for (my $i = 0; $i < @$queue; ) {
    my $q = $queue->[$i];
    if ($q->{log} || blessed $q->{iterator} && ($q->{log} = $q->{iterator}->next)) {
      $i++;
    } else {
      splice(@$queue, $i, 1);
    }
  }

  if (@$queue > 1) {
    @$queue = sort {
      $self->{reverse}?
        $a->{log}->committer_gmtime <=> $b->{log}->committer_gmtime :
        $b->{log}->committer_gmtime <=> $a->{log}->committer_gmtime
      } @$queue;
  }

  my $log;
  if (@$queue) {
    $log = $queue->[0]->{log};
    $queue->[0]->{log} = undef;
  }

  $log;
}

1;
__END__

=pod

# ABSTRACT: Split a git log stream into records

=head1 NAME

=head1 SYNOPSIS

    use Git::Repository::Log::Queue::Iterator;

    # use a default Git::Repository context
    my $iter = Git::Repository::Log::Queue::Iterator->new('HEAD~10..');

    # or provide an existing instance
    my $iter = Git::Repository::Log::Queue::Iterator->new( $r, 'HEAD~10..' );
    my $iter = Git::Repository::Log::Queue::Iterator->new([ @r ], 'HEAD~10..' );

    # get the next log record
    while ( my $log = $iter->next ) {
        ...;
    }

=head1 DESCRIPTION

=cut
