#!/usr/bin/env perl
use strict;
use Data::Dumper;
use DBI;
use Scalar::Util qw(looks_like_number);
use Locale::Currency::Format;

my $path = `pwd`;
chomp($path);
my @files;

opendir(DIR, $path);
@files = grep { /\.txt$/ } readdir(DIR);
closedir(DIR);

#loop em
foreach (@files) {
	my @lines = ();
	my $filename = "$_";
	open(MYINPUTFILE, "<$_"); # open for input
	@lines = <MYINPUTFILE>; # read file into list
	close(MYINPUTFILE);
	
	# my $wholefile = join ' ', @lines;
	# my $first = 0;

	my @writeme = (); my @moneydetails = ();
	my $aLine;

	if ($lines[-1] !~ /-30-/) { #skip files we've processed already
		foreach $aLine (@lines) {
			if (my @lineParts = $aLine =~ /\| (authorizationsofappropriations|appropriations) = (.+),/) {
				print "$filename: \n";
				my $header = $lineParts[0]; #the line we'll build back up
				push @moneydetails, [$header, ':'];
				my $approps = $lineParts[1];
				my @eachApprop = $approps =~ m/\[.*?\]/g;
				my $totals = 0; my $allnumbers = 1;
				foreach my $oneApprop (@eachApprop) {
					my($moneystring, $yearstring);
					my($money,$years) = $oneApprop =~ m/\(amount:(.*)\|year:(.*)\)/g;
					#kill the leading and trailing whitespace
					# $money =~ s/^\s+|\s+$//g;
					# $years =~ s/^\s+|\s+$//g;
					#KILL ALL WHITESPACE
					$money =~ tr/ //ds;
					$years =~ tr/ //ds;
									
					#my @appropParts = $oneApprop =~ m/\(amount:(.*)\|year:(.*)\)/g;
					if (looks_like_number($money)) {
#						print "$money, ";
						$totals = $totals + $money;
						$moneystring = currency_format('usd',$money,FMT_SYMBOL);#. " over years: $years";
					} else {
#						print "we got a non numeric in here!\n";
						$allnumbers = 0;
						$moneystring = "$money";
						#push @moneydetails, "$money over years: $years";
					}
					#push @moneydetails, "$money over years: $years";
					#now let's figure out the year syntax
					#wow I look like a first year... don't judge me - I had a matching brace issue!
					if ($years =~ m/^(\d+)$/) { # when y:
#						print "only a year: $years\n";
						#match the year, output "in fiscal [year]”
						#in this case we just did it in the find since it's pretty simple; it's in $1
						$yearstring = "in fiscal year $1."
					}
					else {
						if ($years =~ m/^[\d,]+$/) { #when y,y,y,y:
#							print "years and commas : $years\n";
							#match multiple years - every number cluster (which is nice and easy since it's comma sep)
							my (@allyears) = $years =~ m/(\d+)/g;
							$yearstring = "for each of fiscal years " . join(', ', @allyears);
							#find the last , YYYY and replace it with and
							$yearstring =~ s/, (\d+)$/ and $1/;
						}
						else {
							if ($years =~ m/(\d+)\.\.(\d+)/) {# when y..y:
#								print "year..year : $years\n";
								#also simple, matched on $1 $2
								#over fiscal [firstyear] through [lastyear]”
								$yearstring = "over fiscal $1 through $2";
							} else {
								if ($years =~ m/(\d+),\.\./) {# when y,..: # when y..:
#									print "year,.. : $years\n";
									#matched on $1
									$yearstring = "in fiscal $1 and each succeeding fiscal year";
								} else {
									if ($years =~ m/(\d+)\.\./) {#when y..:
#										print "year.. : $years\n";
										#matched on $1
										$yearstring = "in fiscal $1, to be spent at any time";
									} else { #must be blank
#										print "blank/indef : $years\n";
										$yearstring = "";
									}
								}
							}
						}
					}
					push @moneydetails, [$moneystring,$yearstring];

				} #end looping the approp(s)

				#at this point we can check to see if our yearstrings are all identical
				#if so we're going to shitcan them all and we'll just be using the total
				#if they are consistent then we can present the total with just this one yearstring
				#NOTE: we must skip position [0] since we're using it to identify approp type
				my @processarray = @moneydetails;
				shift @processarray;
				my $lastvalue = shift @processarray;
				my $mismatchedyears = 0;
  				foreach my $nextvalue (@processarray) {
  					if (@$lastvalue[1] ne @$nextvalue[1]) {
#						print "MISMATCH\n";
#						print "\t@$lastvalue[1]\n\t@$nextvalue[1]\n";
						$mismatchedyears = 1;
					}
					$lastvalue = $nextvalue;
				}

				my $newline;

				if ($allnumbers) {
					#push @writeme, 
					$newline = "| $header = ".currency_format('usd',$totals,FMT_SYMBOL);				
				} else {
					$newline = "| $header = an unlimited amount";
				}

				#tack on the appropriate year ender
				if ($mismatchedyears) {
					$newline = $newline . "\n";
				} else {
					$newline = $newline . " @$lastvalue[1]\n";
				}
				push @writeme, $newline;
			} else { #for the moment non-approp lines pass through unaltered
				push @writeme, $aLine;
			}
		} #end foreach line

		#open the file
		open(INFOBOX, ">$filename")  || die $!;	
		#write out the fields
		foreach (@writeme) {
			print INFOBOX $_;
		}
		print INFOBOX "++++++++++++++++++++++++++++++\n\n\n";

		foreach my $aMoney (@moneydetails) {
			print INFOBOX @$aMoney[0] . ' ' . @$aMoney[1] . "\n";
		}	
		#add any supplimental information. auto-grab from govtrack?	

		print INFOBOX "\n-30-";
		close INFOBOX;

	} #unprocessed files
	else {
		print "Skipping $filename\n";
	}
} #each file