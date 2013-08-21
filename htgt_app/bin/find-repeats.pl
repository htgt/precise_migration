#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::Utils::Design::FindRepeats 'report_repeats';

while ( <> ) {
    chomp;    
    report_repeats( split );    
}


