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

  # default git_dir
  @r = Git::Repository->new() unless @r;

  # setup iterators
  my @queue = map { +{ iterator => scalar $_->log(@cmd), r => $_ } } @r;

  # order for the next()
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

=head1 NAME

Git::Repository::Log::Queue::Iterator - Get a log from set of git-log streams


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


=head1 AUTHOR

KUBO Koichi  C<< <k@obuk.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, KUBO Koichi C<< <k@obuk.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
