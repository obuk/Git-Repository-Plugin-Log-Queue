package Git::Repository::Plugin::Log::Queue;

use warnings;
use strict;
use Carp;

=head1 NAME

Git::Repository::Plugin::Log::Queue - git log multi-repos


=head1 VERSION

This document describes Git::Repository::Plugin::Log::Queue version 0.0.3


=cut

use version;
our $VERSION = qv('0.0.3');


=head1 SYNOPSIS

    # load mailmap plugin
    use Git::Repository 'Log::Queue';

    my $q = Git::Repository->queue([ @repos ], @cmd);
    my $q = Git::Repository->queue(@cmd);

=cut


use Git::Repository::Plugin;
our @ISA      = qw( Git::Repository::Plugin );
sub _keywords { qw( log_queue ) }

use Git::Repository qw( Log );
# use Git::Repository::Log::Iterator;
use Git::Repository::Log::Queue::Iterator;

sub log_queue {
  # skip the invocant when invoked as a class method
  shift if !ref $_[0];

  # get the iterator
  my $iter = Git::Repository::Log::Queue::Iterator->new(@_);

  # scalar context: return the iterator
  return $iter if !wantarray;

  # list context: return all Git::Repository::Log objects
  my @logs;
  while ( my $log = $iter->next ) {
    push @logs, $log;
  }
  return @logs;
}

1;
__END__

=head1 SEE ALSO

L<Git::Repository::Log>


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to the web interface at
L<https://github.com/obuk/Git-Repository-Plugin-Log-Queue/issues>


=head1 AUTHOR

KUBO Koichi  C<< <k@obuk.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, KUBO Koichi C<< <k@obuk.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
