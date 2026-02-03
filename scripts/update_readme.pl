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
my %existing;
my @pre_table;
my @table_lines;
my @post_table;
my $has_table = 0;

sub extract_metadata {
  my ($file_path) = @_;
  open my $fh, '<', $file_path or return '';
  my $title = '';
  my $published = '';
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
    }
    if ($line =~ /^published:\s*(.+)\s*$/) {
      $published = $1;
      $published =~ s/^["']//;
      $published =~ s/["']$//;
    }
  }
  close $fh;
  return ($title, $published);
}

if (-f $readme_path) {
  open my $in, '<', $readme_path or die "Cannot read $readme_path: $!";
  my $in_table = 0;
  while (my $line = <$in>) {
    if ($line =~ /^\|\s*\S+/) {
      $in_table = 1;
      $has_table = 1;
      push @table_lines, $line;
      if ($line =~ /^\|\s*([^|]+?)\s*\|/) {
        my $path = $1;
        $path =~ s/^\s+//;
        $path =~ s/\s+$//;
        $existing{$path} = 1 if $path ne '';
      }
      next;
    }
    if ($in_table) {
      push @post_table, $line;
    } else {
      push @pre_table, $line;
    }
  }
  close $in;
}

find(
  {
    wanted => sub {
      return unless -f $_;
      return unless $_ =~ /\.md\z/;
      my $file_path = $File::Find::name;
      my $relative = File::Spec->abs2rel($file_path, $cwd);
      return if $existing{$relative};
      my ($title, $published) = extract_metadata($file_path);
      my $status = '';
      if ($published ne '') {
        $status = $published =~ /^(true|1|yes)$/i ? '公開' : '下書き';
      }
      push @entries, [$relative, $title, $status];
    },
    no_chdir => 1,
  },
  $root_path
);

open my $out, '>', $readme_path or die "Cannot write $readme_path: $!";
if (@pre_table) {
  print $out @pre_table;
} else {
  print $out "# zenn-articles\n\n" unless $has_table;
}
for my $entry (@entries) {
  print $out '| ' . $entry->[0] . ' | ' . $entry->[1] . ' | ' . $entry->[2] . " |\n";
}
if (@table_lines) {
  print $out @table_lines;
}
if (@post_table) {
  print $out @post_table;
}
close $out;
