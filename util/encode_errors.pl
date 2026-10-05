#!/usr/bin/env perl

use warnings;

# OpenXTalk Lite 1.15: a source file that holds both of Tom Perry's
# versions (his macOS one and his Windows one, see CHANGES-FROM-TOM.md)
# marks the regions where they differ. The compiler takes one version
# through #if defined(_MACOSX); this script reads the file as text, so it
# keeps the lines of the version for the platform being built: gyp's OS,
# "mac" for macOS, any other value (or none) for the Windows version.
sub selectPlatformLines
{
	my ($platform, @lines) = @_;
	my $macos = defined($platform) && $platform eq 'mac';
	my @out = ();
	my $state = '';
	foreach my $line (@lines)
	{
		my $text = $line;
		$text =~ s/[\r\n]+$//;
		if ($text eq '#if defined(_MACOSX) /* OXT-TOM: macOS */') { $state = 'mac'; next; }
		if ($text eq '#if !defined(_MACOSX) /* OXT-TOM: Windows */') { $state = 'win'; next; }
		if ($text eq '#else /* OXT-TOM: Windows */') { $state = 'win'; next; }
		if ($text eq '#endif /* OXT-TOM */') { $state = ''; next; }
		next if ($state eq 'mac' && !$macos);
		next if ($state eq 'win' && $macos);
		push @out, $line;
	}
	return @out;
}

sub generateErrorsList
{
	my $sourceFile = $_[0];
	my $name = $_[1];
	my $platform = $_[2];
	
	my $array = "const char * ${name} = \n";
	
	open SOURCE, "<$sourceFile"
		or die "Could not open \"$sourceFile\": $!";
	my @lines = selectPlatformLines($platform, <SOURCE>);
	close SOURCE;
	
	my $found = 0;
	foreach $line (@lines)
	{
		# If the first word of the line is "enum" we have found the error list
		if ($line =~ /^\s*enum\s/)
		{
			$found = 1;
		}
		
		# Continue reading lines until we get to the enum
		if (!$found)
		{
			next;
		}
		
		# End of the enum
		if ($line =~ /};/)
		{
			last;
		}
		
		# The comment contains the error message for this error
		if ($line =~ m|^\s*//\s*\{|)
		{
			# Remove the newline character
			substr($line, -1) = "";
			
			# Remove the prefix from the error message
			$line =~ s|^\s*//\s*\{[^\}]*\}\s*|| ;
			
			# Protect any quotation marks
			$line =~ s/\"/\\\"/g ;
			
			# Output the message
			# tab & quote & line & "\n" & quote & return
			$array .= "\t\"${line}\\n\"\n";
		}
	}
	
	$array .= ";\n";
	return $array;
}

# Need to generate the error lists for both the parse and execution errors
my $path = $ARGV[0];
my $outputFile = $ARGV[1];
my $platform = $ARGV[2];

my $output = "";
$output .= generateErrorsList("${path}/executionerrors.h", "MCexecutionerrors", $platform);
$output .= "\n";
$output .= generateErrorsList("${path}/parseerrors.h", "MCparsingerrors", $platform);

# Write out the error lists
open OUTPUT, ">$outputFile"
	or die "Could not open output file \"$outputFile\": $!";
print OUTPUT $output;
close OUTPUT;
