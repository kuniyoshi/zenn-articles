#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;
use Cwd qw(abs_path);
use File::Spec;

my $root = $ARGV[0] // 'articles';
my $cwd = abs_path('.');
my $root_path = File::Spec->catdir($cwd, $root);
my $readme_path = File::Spec->catfile($cwd, 'README.md');
my @entries;

sub extract_title {
  my ($file_path) = @_;
  open my $fh, '<', $file_path or return '';
  my $title = '';
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
  return $title;
}

find(
  {
    wanted => sub {
      return unless -f $_;
      return unless $_ =~ /\.md\z/;
      my $file_path = $File::Find::name;
      my $relative = File::Spec->abs2rel($file_path, $cwd);
      my $title = extract_title($file_path);
      push @entries, [$relative, $title];
    },
    no_chdir => 1,
  },
  $root_path
);

@entries = sort { $a->[0] cmp $b->[0] } @entries;

open my $out, '>', $readme_path or die "Cannot write $readme_path: $!";
print $out "# zenn-articles\n\n";
for my $entry (@entries) {
  print $out '| ' . $entry->[0] . ' | ' . $entry->[1] . " |\n";
}
close $out;
