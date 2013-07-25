# TRAPutils (genetrap specific non-database/non-TK methods)
#
# Author: Lucy Stebbings (las)
#

package TRAPutils;

use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(make_barcode_image getIdFromBarcode getPrefixFromBarcode translate_well convertAlphanumeric convertSlotId check_date reform_date reverseSeq getGCcontent getMW);

# getIdFromBarcode - extracts the internal id from a barcode
# getPrefixFromBarcode - gets the prefix from a barcode

use strict;

use lib '/usr/local/share/perl/5.8.4';

use Barcode::Code128;
use Checkbarcode2;
use Carp;
use MIME::Base64;

#-------------------------------------------------------------------------------------------------------#

sub make_barcode_image {

    my $pkg = shift;
    my $prefix = shift;
    my $id = shift;    # this is numeric, need ID and a checksum added plus make it numeric

#    $prefix = 'ZZ'; $id = 100000;

    # This Checkbarcode2 method isn't calculating the same number that is on the barcode??? 
    # a number is missing from the end each time???
    # whats happening?
    my ($text, $hr) = Calculatebarcode($prefix,$id);
    print "prefix $prefix id $id bc $text hr $hr\n";

   # when using the numeric version not human readable, 
   #seem to need to add a number to the end (doesnt seem to matter what!) so that the barcode is validated
   # (stops checkbarcode2 adding a 0 to the front of the barcode number - why?!??)
   # this worked with all the numbers/prefixes I tried but may be a problem later
#    if (length($text) == 12) { $text = $text . "0"; }
   # Matthew suggests using the Alphanumeric anyway because it makes a shorter barcode

    print "final text is $text\n";
    my $barcode = new Barcode::Code128;
    $barcode->scale(1);
    $barcode->border(0);
    $barcode->padding(0);
    $barcode->width(130);
    $barcode->height(25);
    $barcode->font('small');
    $barcode->show_text(0);
    $barcode->transparent_text(1);
#    $barcode->show_text(1);
#    $barcode->text($text);
    # have to change the image from GDs 8(?) bit encoding to 64 bit so that Tk can use it
    # need the MIME::Base64 package to do this.
    # if you dont do this you have to print it to file then read it in again in Tk
    my $barcode_image = encode_base64($barcode->png($hr));

    return($barcode_image, $hr);
}

#-------------------------------------------------------------------------------------------------------#
# getIdFromBarcode - extracts the internal id from a barcode

sub getIdFromBarcode {

    my $pkg = shift;
    my $barcode = shift;

    return unless ($barcode);

    my $result = Checkbarcode2::Verifynumber($barcode);
    croak $result->{Process} . " user barcode" unless $result->{Process} eq 'Good';
#   croak "Bad barcode id" unless $result->{Type} eq 'ID';
    my $id = $result->{Number};

    return($id);
}
#-------------------------------------------------------------------------------------------------------#
# getPrefixFromBarcode - gets the prefix from a barcode

sub getPrefixFromBarcode {

    my $pkg = shift;
    my $barcode = shift;

    print "barcode $barcode\n";
    return unless ($barcode);

    if ($barcode =~ /^(\D\D)/) { return $1; }

    print "get barcode prefix for $barcode\n";
    my $result = Checkbarcode2::Verifynumber($barcode);
#    croak $result->{Process} . " user barcode" unless $result->{Process} eq 'Good';
    foreach (keys %$result) {
	print "$_ $result->{$_}\n";
    }
#   croak "Bad barcode id" unless $result->{Type} eq 'ID';
    my $prefix = $result->{Type};
    print "prefix $prefix\n";
    return($prefix);
}
#-------------------------------------------------------------------------------------------------------#
# label wells 1A = 11, 1B = 12, 2A = 21, 3C = 33 etc
# (human readables need to be A1, A2 etc)
# this means you can sort them numerically to move down columns
# which is what happens in the lab
# this is also OK for dewars - fill up a rack at a time then move on to the next rack (rack=column)
# BUT freezer boxes are filled row by row, so row and col need swapping over before passing to this sub
sub translate_well {
    my $pkg = shift;
    my $well = shift;

    my ($row, $column);

#    print "well $well  to   ";

    if ($well =~ /^(\d\d)(\d)$/) {
	$column = $1;
	$row = $2;
	$row = $pkg->convertAlphanumeric($row);
	$row = uc($row);
	$well = $row . $column;
    }

    elsif ($well =~ /^(\d)(\d)$/) {
	$column = $1;
	$row = $2;
	$row = $pkg->convertAlphanumeric($row);
	$row = uc($row);
	$well = $row . $column;
    }

    elsif ($well =~ /^(\d)(\D)/) {
	$column = $1;
	$row = lc($2);
	$row = $pkg->convertAlphanumeric($row);
	$row = uc($row);
	$well = $column . $row;
    }

    elsif ($well =~ /^(\D)(\d)/) {
	$row = lc($1);
	$column = $2;
	$row = $pkg->convertAlphanumeric($row);
	$row = uc($row);
	$well = $column . $row;
    }

#    print "$well\n";
    return $well;
}

#-------------------------------------------------------------------------------------------------------#

sub convertAlphanumeric {

    my $pkg = shift;
    my $alphanumeric = shift;
    return unless ($alphanumeric);

    if ($alphanumeric =~ /\D/) {
        if ($alphanumeric eq 'a') { $alphanumeric = 1; }
        elsif ($alphanumeric eq 'b') { $alphanumeric = 2; }
        elsif ($alphanumeric eq 'c') { $alphanumeric = 3; }
        elsif ($alphanumeric eq 'd') { $alphanumeric = 4; }
        elsif ($alphanumeric eq 'e') { $alphanumeric = 5; }
        elsif ($alphanumeric eq 'f') { $alphanumeric = 6; }
        elsif ($alphanumeric eq 'g') { $alphanumeric = 7; }
        elsif ($alphanumeric eq 'h') { $alphanumeric = 8; }
        elsif ($alphanumeric eq 'i') { $alphanumeric = 9; }
        elsif ($alphanumeric eq 'j') { $alphanumeric = 10; }
        elsif ($alphanumeric eq 'k') { $alphanumeric = 11; }
        elsif ($alphanumeric eq 'l') { $alphanumeric = 12; }
    }
    elsif ($alphanumeric =~ /\d/) {
        if ($alphanumeric == 1) { $alphanumeric = 'a'; }
        elsif ($alphanumeric == 2) { $alphanumeric = 'b'; }
        elsif ($alphanumeric == 3) { $alphanumeric = 'c'; }
        elsif ($alphanumeric == 4) { $alphanumeric = 'd'; }
        elsif ($alphanumeric == 5) { $alphanumeric = 'e'; }
        elsif ($alphanumeric == 6) { $alphanumeric = 'f'; }
        elsif ($alphanumeric == 7) { $alphanumeric = 'g'; }
        elsif ($alphanumeric == 8) { $alphanumeric = 'h'; }
        elsif ($alphanumeric == 9) { $alphanumeric = 'i'; }
        elsif ($alphanumeric == 10) { $alphanumeric = 'j'; }
        elsif ($alphanumeric == 11) { $alphanumeric = 'k'; }
        elsif ($alphanumeric == 12) { $alphanumeric = 'l'; }
    }

    return ($alphanumeric);
}

#-------------------------------------------------------------------------------------------------------#

# takes a LN2 box slot number and turn it into a row and column
sub convertSlotId {

    my $pkg = shift;
    my $slot_number = shift;

    my ($row, $col);

    if ($slot_number < 10) { $row = 1; }
    elsif ($slot_number < 19) { $row = 2; }
    elsif ($slot_number < 28) { $row = 3; }
    elsif ($slot_number < 37) { $row = 4; }
    elsif ($slot_number < 46) { $row = 5; }
    elsif ($slot_number < 55) { $row = 6; }
    elsif ($slot_number < 64) { $row = 7; }
    elsif ($slot_number < 73) { $row = 8; }
    elsif ($slot_number < 82) { $row = 9; }

    if ((($slot_number + 8)%9) == 0) { $col = 1; }
    elsif ((($slot_number + 7)%9) == 0) { $col = 2; }
    elsif ((($slot_number + 6)%9) == 0) { $col = 3; }
    elsif ((($slot_number + 5)%9) == 0) { $col = 4; }
    elsif ((($slot_number + 4)%9) == 0) { $col = 5; }
    elsif ((($slot_number + 3)%9) == 0) { $col = 6; }
    elsif ((($slot_number + 2)%9) == 0) { $col = 7; }
    elsif ((($slot_number + 1)%9) == 0) { $col = 8; }
    elsif (($slot_number%9) == 0) { $col = 9; }

    return($row, $col);

}

#----------------------------------------------------------------------------------------------#

sub check_date {

    my $pkg = shift;
    my $date = shift;
    my ($day, $month, $year, $cent, $dec);

    if (($date =~ /\s*(\d?\d)[\/\\_-](\d?\d)[\/\\_-](\d?\d?\d\d)\s*/) || 
       ($date =~ /\s*(\d?\d)[\/\\_-](\S\S\S)[\/\\_-](\d?\d?\d\d)\s*/)) {
	$day = $1;
	$month = $2;
	$year = $3;
	$day =~ s/^0//;
	$month =~ s/^0//;
        # check the dates are valid
	return(0) if ($day > 31);
	return(0) if (($month =~ /\d\d?/) && ($month > 12));
	if ($year =~ /(\d\d)(\d\d)/) {
	    $cent = $1;
	    $dec = $2;
	    $dec =~ s/^0//;
	    return(0) unless (($cent eq '19') || ($cent eq '20'));
	}
	elsif ($year =~ /(\d\d)/) {
	    $dec = $1;
	}
        return(0) unless (($dec > 80) || ($dec < 20));

	if ($dec > 80) { $cent = 19; }
	if ($dec < 20) { $cent = 20; }
	$dec =~ s/^(\d)$/0$1/;
	($dec = "00") unless ($dec);
	$year = $cent . $dec;

	if ($day =~ /^\d$/) { $day = '0' . $day; }
	if ($month =~ /^\d$/) { $month = '0' . $month; }

	if ($month =~ /\D\D\D/) {$month = uc($month); }

	if ($month eq "01") {$month = 'JAN'}
	elsif ($month eq "02") {$month = 'FEB'}
	elsif ($month eq "03") {$month = 'MAR'}
	elsif ($month eq "04") {$month = 'APR'}
	elsif ($month eq "05") {$month = 'MAY'}
	elsif ($month eq "06") {$month = 'JUN'}
	elsif ($month eq "07") {$month = 'JUL'}
	elsif ($month eq "08") {$month = 'AUG'}
	elsif ($month eq "09") {$month = 'SEP'}
	elsif ($month eq "10") {$month = 'OCT'}
	elsif ($month eq "11") {$month = 'NOV'}
	elsif ($month eq "12") {$month = 'DEC'}

        $date = $day . "-" . $month . "-" . $year;
	return($date) if ($date);
    }
    return(0); 
}

#------------------------------------------------------------------------------------------------#


sub reform_date {

    my $pkg = shift;
    my $date = shift;
    my ($day, $month, $year, $cent, $dec);

#    print "here is the date $date\n";
    if ($date =~ /^\s*(\d?\d?\d\d)[\/\\_-](\d?\d)[\/\\_-](\d?\d)\s*/) {
	$year = $1;
	$month = $2;
	$day = $3;
	$day =~ s/^0//;
	$month =~ s/^0//;
#        print "year $year month $month day $day\n";
        # check the dates are valid
	return(0) if ($day > 31);
	return(0) if (($month =~ /\d\d?/) && ($month > 12));
	if ($year =~ /(\d\d)(\d\d)/) {
	    $cent = $1;
	    $dec = $2;
	    $dec =~ s/^0//;
	    return(0) unless (($cent eq '19') || ($cent eq '20'));
	}
	elsif ($year =~ /(\d\d)/) {
	    $dec = $1;
	}
        return(0) unless (($dec > 80) || ($dec < 20));

	if ($dec > 80) { $cent = 19; }
	if ($dec < 20) { $cent = 20; }
	$dec =~ s/^(\d)$/0$1/;
	($dec = "00") unless ($dec);
	$year = $cent . $dec;

	if ($day =~ /^\d$/) { $day = '0' . $day; }
	if ($month =~ /^\d$/) { $month = '0' . $month; }

	if ($month eq "01") {$month = 'Jan'}
	elsif ($month eq "02") {$month = 'Feb'}
	elsif ($month eq "03") {$month = 'Mar'}
	elsif ($month eq "04") {$month = 'Apr'}
	elsif ($month eq "05") {$month = 'May'}
	elsif ($month eq "06") {$month = 'Jun'}
	elsif ($month eq "07") {$month = 'Jul'}
	elsif ($month eq "08") {$month = 'Aug'}
	elsif ($month eq "09") {$month = 'Sep'}
	elsif ($month eq "10") {$month = 'Oct'}
	elsif ($month eq "11") {$month = 'Nov'}
	elsif ($month eq "12") {$month = 'Dec'}

#        print " day $day  month $month year $year\n";
        $date = $day . "-" . $month . "-" . $year;
	return($date) if ($date);
    }
    return(0); 
}

#---------------------------------------------------------------------------------------#


sub getGCcontent {

    my $sequence = shift;
    my $seq = lc($sequence);

    my $length = length($sequence);
    my $G = lc($seq) =~ tr/g//;
    my $C = lc($seq) =~ tr/c//;

    my $GCcontent = ($G + $C)/$length;
    my $GC = sprintf "%.3f", $GCcontent; 


    return($GC);
}

#-------------------------------------------------------------------------------------------------------#

sub getMW {

    my $sequence = shift;

    # make sure we are in the same case
    my $seq = lc($sequence);

    # tr (translate) returns the number of characters it has changed
    my $G = lc($seq) =~ tr/g//;
    my $C = lc($seq) =~ tr/c//;
    my $A = lc($seq) =~ tr/a//;
    my $T = lc($seq) =~ tr/t//;

    my $MW = ($A * 312.2) + ($C * 288.2) + ($G * 328.2) + ($T * 303.2);

    return($MW);
}

#-------------------------------------------------------------------------------------------------------#

sub reverseSeq {

    my $seq = shift;
#    print "seq in $seq\n";
    my $sequence = uc($seq);

    my @sequence = split '', $sequence;

    foreach (@sequence) {
	if    ($_ eq 'A') { $_ = 'T' }
	elsif ($_ eq 'T') { $_ = 'A' }
	elsif ($_ eq 'G') { $_ = 'C' }
	elsif ($_ eq 'C') { $_ = 'G' }
    }

    my @rev = reverse @sequence;
    my $rev = join '', @rev;

#    print "seq out $rev\n\n";
    return($rev);

}

#-------------------------------------------------------------------------------------------------------#

1;
