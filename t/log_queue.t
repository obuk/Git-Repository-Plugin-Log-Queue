# -*- mode: perl -*-
use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok("Git::Repository");
  use_ok(my $plugin = "Git::Repository::Plugin::Log::Queue");
  $plugin->install();
  can_ok('Git::Repository', 'log_queue');
}

use Cwd;
use File::Slurp qw/ write_file /;
use File::Spec::Functions qw/ catfile /;
use Test::Git;

$ENV{GIT_AUTHOR_EMAIL}    = 'author@example.com';
$ENV{GIT_AUTHOR_NAME}     = 'Author Name';
$ENV{GIT_COMMITTER_EMAIL} = 'committer@example.com';
$ENV{GIT_COMMITTER_NAME}  = 'Committer Name';

{
  my @r = (test_repository, test_repository, test_repository);

  my $j = 1;
  for my $i (0 .. 2) {
    for my $r (@r) {
      my $f = "hw$i.txt";
      write_file(catfile($r->work_tree, $f), "hello, world");
      $r->run(add => $f);
      $r->run(commit => -m => "$i $j");
      $j++;
    }
    sleep 1;
  }

  my $lasti;
  for (Git::Repository->log_queue([@r])) {
    my $i = $_->message =~ /(\d+)/;
    cmp_ok $i, '<=', $lasti if defined $lasti;
    $lasti = $i;
  }

  $lasti = undef;
  for (Git::Repository->log_queue([@r], '--reverse')) {
    my $i = $_->message =~ /(\d+)/;
    cmp_ok $i, '>=', $lasti if defined $lasti;
    $lasti = $i;
  }

  $lasti = undef;
  for (Git::Repository->log_queue(map { "--git-dir=" . $_->git_dir } @r)) {
    my $i = $_->message =~ /(\d+)/;
    cmp_ok $i, '<=', $lasti if defined $lasti;
    $lasti = $i;
  }

}

done_testing();
