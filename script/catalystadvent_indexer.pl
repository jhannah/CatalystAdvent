#!/usr/local/bin/perl
use strict;
use warnings;

use FindBin qw/ $Bin /;
my $path_to_index = "$Bin/../root/adventindex";
my $articles      = "$Bin/../root";
use lib "$Bin/../lib";
use CatalystAdvent::Pod;
use File::Spec::Functions qw( catfile );
use Pod::Parser;
use File::Where qw/ where /;
use File::Find::Rule;
use KinoSearch::Schema;
use KinoSearch::FieldType::FullTextType;
use KinoSearch::Analysis::PolyAnalyzer;
use KinoSearch::Indexer;

# Create Schema.
my $schema = KinoSearch::Schema->new;
my $polyanalyzer = KinoSearch::Analysis::PolyAnalyzer->new( language => 'en', );
my $title_type =
  KinoSearch::FieldType::FullTextType->new( analyzer => $polyanalyzer, );
my $content_type = KinoSearch::FieldType::FullTextType->new(
    analyzer      => $polyanalyzer,
    highlightable => 1,
);
my $url_type = KinoSearch::FieldType::StringType->new( indexed => 0, );
my $cat_type = KinoSearch::FieldType::StringType->new( stored  => 0, );
$schema->spec_field( name => 'title',    type => $title_type );
$schema->spec_field( name => 'content',  type => $content_type );
$schema->spec_field( name => 'url',      type => $url_type );
$schema->spec_field( name => 'category', type => $cat_type );

# Create an Indexer object.
my $indexer = KinoSearch::Indexer->new(
    index    => $path_to_index,
    schema   => $schema,
    create   => 1,
    truncate => 1,
);

# Collect names of source html files.
my @subdirs = File::Find::Rule->directory->in($articles);
my @filenames = File::Find::Rule->file()->name( '*.pod')->in(@subdirs);
# Iterate over list of source files.
for my $filename (@filenames) {
    print "Indexing $filename\n";
    my $doc = parse_file($filename);
    $indexer->add_doc($doc);
}

# Finalize the index and print a confirmation message.
$indexer->commit;
print "Finished.\n";

sub parse_file {
    my ($filename) = @_;
    my $parser = CatalystAdvent::Pod->new();
    my $where = where($filename, '', 'nofile');
	open my $fh, '<:utf8', $filename or die "Failed to open $filename: $!";
	$parser->parse_from_filehandle($fh);
	close $fh;

	my @dirs = split('/', $where);
	my $year = pop @dirs;

	my $category =
        $parser->title =~ /catalyst/i               ? 'catalyst'
      : $parser->title =~ /template\:\:toolkit/i    ? 'template-toolkit'
      : $parser->title =~ /dbix\:\:class/i          ? 'dbix-class'
	  : $parser->title =~ /cache/i                  ? 'caching'
      :                           "Catalyst";
    
	return {
        title    => $parser->title,
        content  => $parser->summary,
        url      => "/$year/$filename",
        category => $category,
    };
}
