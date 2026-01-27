#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;
use Cwd qw(abs_path);
use File::Spec;

my $root = $ARGV[0] // 'articles';
my $cwd = abs_path('.');
my $root_path = File::Spec->catdir($cwd, $root);

find(
  {
    wanted => sub {
      return unless -f $_;
      my $file_path = $File::Find::name;
      my $title = '';
      open my $fh, '<', $file_path or return;
      my $in_front_matter = 0;
      while (my $line = <$fh>) {
        chomp $line;
        if ($line eq '---') {
          if ($in_front_matter) {
            last;
          }
          $in_front_matter = 1;
          next;
        }
        next unless $in_front_matter;
        if ($line =~ /^title:\s*(.+)\s*$/) {
          $title = $1;
          $title =~ s/^["']//;
          $title =~ s/["']$//;
          last;
        }
      }
      close $fh;

      my $relative = File::Spec->abs2rel($file_path, $cwd);
      print $relative . "\t" . $title . "\n";
    },
    no_chdir => 1,
  },
  $root_path
);
