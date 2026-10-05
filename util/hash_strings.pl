#!/usr/bin/env perl

use warnings;
use File::Basename;
use File::Temp qw(tempfile);

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

# Arguments
my $sourceFile = $ARGV[0];
my $targetFile = $ARGV[1];
my $perfectCmd = $ARGV[2];
my $platform = $ARGV[3];

# Get the input
open SOURCE, "<$sourceFile"
	or die "Could not open source file \"$sourceFile\": $!";
my @sourceLines = selectPlatformLines($platform, <SOURCE>);
close SOURCE;

# List of tokens
my %tokens = ();

# Look for the lines with the following properties:
#	The first token is "{"
#	The second token is a C-string
foreach my $line (@sourceLines)
{
	# Does the line begin with a { token?
	if (!($line =~ s/^\s*\{\s*//g))
	{
		next;
	}

	# Is the next token a C-string?
	if (substr($line, 0, 1) ne '"')
	{
		next;
	}

	# Scan to the end of the string
	# NOTE: embedded quotation marks are not handled correctly!
	my $end = index($line, '"', 1);
	if ($end == -1)
	{
		next;
	}

	# Copied over from hash_strings.rev
	if (substr($line, 1, 1) eq '\\')
	{
		next;
	}

	# Add to the list of tokens
	my $token = substr($line, 1, $end-1);
	$tokens{$token} = 1;
}

# Write the list of tokens out to a temporary file
($tempFH, $tempName) = tempfile();
($tempFH2, $tempName2) = tempfile();
print $tempFH join("\n", sort(keys %tokens));
close $tempFH;
close $tempFH2;		# Need to close because Win32 opens exclusively

# Path to the "perfect" executable
my $perfectExe = $perfectCmd;

# Execute the appropriate "perfect" executable
my $result = system("\"$perfectExe\" <\"$tempName\" >\"$tempName2\"");
die unless ($result == 0);

# Strip of any leading warning message
open $tempFH2, "<$tempName2";
my @lines = <$tempFH2>;
close $tempFH2;
unlink $tempName;
unlink $tempName2;
if (substr($lines[0], 0, 1) ne '#')
{
	splice(@lines, 0, 1);
}

# Write to the output file
open OUTPUT, ">$targetFile"
	or die "Couldn't open output file: $1";
print OUTPUT join('', @lines);
close OUTPUT;
