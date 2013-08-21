#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::Utils::Design::FindConstrainedElements 'report_constrained_elements';

while ( <> ) {
    chomp;    
    report_constrained_elements( split );
}
