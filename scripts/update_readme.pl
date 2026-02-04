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
my %existing_rows;
my @existing_order;
my @pre_table;
my @post_table;
my $has_table = 0;
my $has_pre_table = 0;

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

sub parse_table_line {
  my ($line) = @_;
  return unless $line =~ /^\s*\|/;
  my @cols = split /\|/, $line;
  shift @cols;
  @cols = map {
    my $v = $_;
    $v =~ s/^\s+//;
    $v =~ s/\s+$//;
    $v;
  } @cols;
  return unless @cols >= 3;
  my ($path, $title, $status) = @cols[0,1,2];
  return if $path eq '';
  return ($path, $title, $status);
}

if (-f $readme_path) {
  open my $in, '<', $readme_path or die "Cannot read $readme_path: $!";
  my $in_table = 0;
  while (my $line = <$in>) {
    if ($line =~ /^\|\s*\S+/) {
      $in_table = 1;
      $has_table = 1;
      my ($path, $title, $status) = parse_table_line($line);
      if (defined $path) {
        $existing_rows{$path} = { title => $title, status => $status };
        push @existing_order, $path;
      }
      next;
    }
    if ($in_table) {
      push @post_table, $line;
    } else {
      $has_pre_table = 1 if $line =~ /\S/;
      push @pre_table, $line;
    }
  }
  close $in;
}

my %entries_by_path;
find(
  {
    wanted => sub {
      return unless -f $_;
      return unless $_ =~ /\.md\z/;
      my $file_path = $File::Find::name;
      my $relative = File::Spec->abs2rel($file_path, $cwd);
      my ($title, $published) = extract_metadata($file_path);
      my $status = '';
      if ($published ne '') {
        $status = $published =~ /^(true|1|yes)$/i ? '公開' : '下書き';
      }
      $entries_by_path{$relative} = [$relative, $title, $status];
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

my %written;
for my $path (@existing_order) {
  my $entry = $entries_by_path{$path};
  if ($entry) {
    print $out '| ' . $entry->[0] . ' | ' . $entry->[1] . ' | ' . $entry->[2] . " |\n";
    $written{$path} = 1;
    next;
  }
  my $row = $existing_rows{$path};
  next unless $row;
  print $out '| ' . $path . ' | ' . $row->{title} . ' | ' . $row->{status} . " |\n";
  $written{$path} = 1;
}

for my $path (sort keys %entries_by_path) {
  next if $written{$path};
  my $entry = $entries_by_path{$path};
  print $out '| ' . $entry->[0] . ' | ' . $entry->[1] . ' | ' . $entry->[2] . " |\n";
}
if (@post_table) {
  print $out @post_table;
}
close $out;
