
# Genetrap.pm
#
# Library module for the Genetrap Project (Tk screen display)
# 
#
# 
# Author: Lucy Stebbings (las) adapted from module by js10

#
#

package Genetrap;
use strict;

use Tk;
use Tk::PNG;            # need to use perl 5.8 to get this working...
use Tk::BrowseEntry;
use Tk::Dialog;
use Tk::Balloon;

use TargetedTrap::GTRAP;
use TargetedTrap::TRAPutils;
use TargetedTrap::GenetrapTk::TRAPsheets;

sub new
{
    my $pkg = shift;

    # Fonts
    my $setup = { 
		"title_f"       => "*-times-bold-r-normal--*-180-*-*-p-*-*-*",
		"button_f"      => "-adobe-helvetica-bold-r-normal--17-120-100-100-p-92-iso8859-1",
		"label_f"       => "-adobe-helvetica-bold-r-normal--14-100-100-100-p-82-iso8859-1",
		"barcode_entry" => "pale green",
		"other_entry"   => "white",
	};
    
    bless ($setup, $pkg);
    return $setup;
}

sub getVersion
{
	return '0.1';
}

sub make_mainwindow
{
    ##### define main window
    my $pkg = shift;
    my $title = shift;
    my $window = shift;   # only defined if this isnt the first window
    my $mw = 'mw';
    if  (defined($window)) {
	$mw .= $window;
    }

    $pkg->{$mw} = MainWindow->new;
    $pkg->{$mw}->wm('minsize', 450, 400); 
    $pkg->{$mw}->bind('<Alt-Key-q>' => sub { exit(0); });
    if (defined($title)) { $pkg->{$mw}->title($title); }
}

sub header
{
     ##### make title and message box

    my $pkg =shift;
    my $title = shift;
    my $window = shift;
    my $mw = 'mw';
    my $header = 'header';
    if  (defined($window)) {
	$mw .= $window;
	$header .= $window;
    }
    my $title_frame = $pkg->{$mw}->Frame(-borderwidth => '6');
    $title_frame->pack(-side => 'top', -fill => 'x');
    
    ##### create title
    $pkg->{$header} = $title_frame->Label( -font =>  $pkg->{title_f},
	                                      -text =>  $title)->pack(-side => 'top');
}


sub user_boxes
{
    #### generic logon/logoff boxes
    my $pkg = shift;
    my $window = shift;
    my $mw = 'mw';
    if  (defined($window)) {
	$mw .= $window;
    }

    ######## make frame
    my $user_frame  = $pkg->{$mw}->Frame(-borderwidth => '6');
    $user_frame->pack(-side => 'top', -expand => 'no', -fill => 'x');
	$pkg->{user_frame} = $user_frame;
    
    ####### header box
    my $title = "User";
    my $bc_user_title = $user_frame->Label( -text => 'User')->pack(-side     => 'left');

    ####### bc entry box
    $pkg->{bc_user_label} = $user_frame->Entry(
					       -width            => 10,
					       -textvariable     => \$pkg->{user_bc}, 
					       -bg               => $pkg->{barcode_entry},
					       )->pack(-side => 'left');
    $pkg->{bc_user_label}->focus();

    $pkg->{bc_name} = $user_frame->Label()->pack(-side=>'left');

    return ($pkg->{bc_user_label});
}

sub plate_boxes
{
    #### generic plate entry boxes
    my $pkg = shift;
    my $window = shift;
    my $mw = "mw";
    my $frame_name = "entry_frame";
    if (defined($window)) { 
        $mw .= $window;
        $frame_name .= $window;
    }

    ######## make frame
    my $entry_frame  = $pkg->{$mw}->Frame(-borderwidth => '6');
    $entry_frame->pack(-side => 'top', -expand => 'no', -fill => 'x');
	$pkg->{$frame_name} = $entry_frame;
    
    ####### header box
    my $title = "plate";
    my $plate_title = $entry_frame->Label( -text => 'plate          ')->pack(-side => 'left');

    ####### bc entry box
    $pkg->{plate_label} = $entry_frame->Entry(
					       -width        => 10,
					       -textvariable => \$pkg->{plate}, 
	                                       -state        => 'disabled',
					       )->pack(-side => 'left');

    $pkg->{plate_result_label} = $entry_frame->Label()->pack(-side=>'left');
    $pkg->{electro_result_label} = $entry_frame->Label()->pack(-side=>'right');

    return ($pkg->{plate_label});
}


sub robot_box
{
    #### generic robot tick box
    my $pkg = shift;
    my $window = shift;
    my $mw = "mw";
    my $frame_name = "entry_frame";
    if (defined($window)) { 
        $mw .= $window;
        $frame_name .= $window;
    }
    ######## make frame
    my $entry_frame  = $pkg->{$mw}->Frame(-borderwidth => '6');
    $entry_frame->pack(-side => 'top', -expand => 'no', -fill => 'x');
	$pkg->{$frame_name} = $entry_frame;
        # if they want to use robot plates
    $entry_frame->Label(-text => 'From Robot?')->pack(-side => 'left');
    my $box;
    if ($pkg->{robot_callback}) {
        $box = $entry_frame->BrowseEntry(-state=>'readonly',
					 -browsecmd => $pkg->{robot_callback},
		                         -variable=>\$pkg->{robot},
		                         -width=>4
                                        )->pack(-side => 'left');
    }
    else {
        $box = $entry_frame->BrowseEntry(-state=>'readonly',
		                         -variable=>\$pkg->{robot},
		                         -width=>4
                                        )->pack(-side => 'left');
    }
    $box->insert('end', 'no', 'yes');
    $pkg->{robot} = 'no';
    return ($box);
}

sub format48_box
{
    #### generic robot tick box
    my $pkg = shift;
    my $window = shift;
    my $mw = "mw";
    my $frame_name = "entry_frame";
    if (defined($window)) { 
        $mw .= $window;
        $frame_name .= $window;
    }
    ######## make frame
    my $entry_frame  = $pkg->{$mw}->Frame(-borderwidth => '6');
    $entry_frame->pack(-side => 'top', -expand => 'no', -fill => 'x');
	$pkg->{$frame_name} = $entry_frame;
        # if they want to use robot plates
    $entry_frame->Label(-text => 'All 48 well? ')->pack(-side => 'left');
    my $box;
    if ($pkg->{format48_callback}) {
        $box = $entry_frame->BrowseEntry(-state=>'readonly',
					 -browsecmd => $pkg->{format48_callback},
		                         -variable=>\$pkg->{format48},
		                         -width=>4
                                        )->pack(-side => 'left');
    }
    else {
        $box = $entry_frame->BrowseEntry(-state=>'readonly',
		                         -variable=>\$pkg->{format48},
		                         -width=>4
                                        )->pack(-side => 'left');
    }
    $box->insert('end', 'no', 'yes');
    $pkg->{format48} = 'no';
    return ($box);
}

sub plate_type
{
    #### generic robot tick box
    my $pkg = shift;
    my $window = shift;
    my $mw = "mw";
    my $frame_name = "entry_frame";
    if (defined($window)) { 
        $mw .= $window;
        $frame_name .= $window;
    }
    ######## make frame
    my $entry_frame  = $pkg->{$mw}->Frame(-borderwidth => '6');
    $entry_frame->pack(-side => 'top', -expand => 'no', -fill => 'x');
	$pkg->{$frame_name} = $entry_frame;
        # if they want to use robot plates
    $entry_frame->Label(-text => 'Plate Type   ')->pack(-side => 'left');
    my $box;
    if ($pkg->{plate_type_callback}) {
        $box = $entry_frame->BrowseEntry(-state=>'readonly',
					 -browsecmd => $pkg->{plate_type_callback},
		                         -variable=>\$pkg->{plate_type},
		                         -width=>4
                                        )->pack(-side => 'left');
    }
    else {
        $box = $entry_frame->BrowseEntry(-state=>'readonly',
		                         -variable=>\$pkg->{plate_type},
		                         -width=>4
                                        )->pack(-side => 'left');
    }
    $box->insert('end', 'M', 'F', 'R', 'S');
    $pkg->{plate_type} = 'R';
    return ($box);
}


sub rearray_box
{
    #### generic rearray tick box
    my $pkg = shift;
    my $window = shift;
    my $mw = "mw";
    my $frame_name = "entry_frame";
    if (defined($window)) { 
        $mw .= $window;
        $frame_name .= $window;
    }
    ######## make frame
    my $entry_frame  = $pkg->{$mw}->Frame(-borderwidth => '6');
    $entry_frame->pack(-side => 'top', -expand => 'no', -fill => 'x');
	$pkg->{$frame_name} = $entry_frame;
        # if they want to use robot plates
    $entry_frame->Label(-text => 'Rearray Type   ')->pack(-side => 'left');
    my $box;
    if ($pkg->{rearray_type_callback}) {
        $box = $entry_frame->BrowseEntry(-state=>'readonly',
					 -browsecmd => $pkg->{rearray_type_callback},
		                         -variable=>\$pkg->{rearray_type},
		                         -width=>12
                                        )->pack(-side => 'left');
    }
    else {
        $box = $entry_frame->BrowseEntry(-state=>'readonly',
		                         -variable=>\$pkg->{rearray_type},
		                         -width=>12
                                        )->pack(-side => 'left');
    }
    $box->insert('end', 'DNA', 'RNA', 'DNA and RNA');
    $pkg->{rearray_type} = 'RNA';
    return ($box);
}


sub regrow_boxes
{
    #### generic regrow entry boxes
    my $pkg = shift;
    my $window = shift;
    my $mw = "mw";
    my $frame_name = "entry_frame";
    if (defined($window)) { 
        $mw .= $window;
        $frame_name .= $window;
    }

    ######## make frame
    my $entry_frame  = $pkg->{$mw}->Frame(-borderwidth => '6');
    $entry_frame->pack(-side => 'top', -expand => 'no', -fill => 'x');
	$pkg->{$frame_name} = $entry_frame;
    
    ####### header box
    my $title = "regrow";
    my $regrow_title = $entry_frame->Label( -text => 'regrow')->pack(-side => 'left');

    ####### regrow id entry box
    $pkg->{regrow_label} = $entry_frame->BrowseEntry(-state=>'readonly',
		                                     -variable=>\$pkg->{regrow_entry},
		                                     -width=>15,
                                                     -browsecmd => sub {
						      ($pkg->{id_regrow}) = ($pkg->{regrow_entry} =~ /^\s*(\d+)\s+/);
						     }
                                                    )->pack(-side => 'left');

#     $pkg->{regrow_label} = $entry_frame->Entry(
#					       -width            => 10,
#					       -textvariable     => \$pkg->{regrow}, 
#	                                       -state                  => 'disabled',
#					       )->pack(-side => 'left');

    $pkg->{regrow_result_label} = $entry_frame->Label()->pack(-side=>'left');
    return ($pkg->{regrow_label});
}




# Quit program function, bound to the 'Quit' button
#
sub _quit
{
	my $pkg = shift;
	my $window = shift;
	my $mw = 'mw';
	if (defined($window)) { $mw .= $window; }
	if (defined($pkg->{entrywidget})) {
		my $c = $pkg->{entrywidget}->infoChildren();
		if (defined($c) && scalar($c)>0) {
			# ask for confirmation
			my $reply = $pkg->{$mw}->Dialog( -title => 'Quit',
			                                -text => 'You have unsaved entries: Are you sure you want to quit?',
			                                -default_button => 'no',
			                                -buttons => ['yes', 'no' ],
			                                -bitmap => 'question')->Show();
			if ($reply ne 'yes') { return; }
		}
	}
	return if ($pkg->{quit_override});
	if (defined($window)) {	$pkg->{$mw}->destroy; }
	$pkg->{mw}->destroy;
	exit;
}

sub _make_button_frame
{
    my ($pkg) = shift;
    my $window = shift;
    my $mw = 'mw';
    my $button_frame = 'button_frame';
    if  (defined($window)) {
	$mw .= $window;
	$button_frame .= $window;
    }
    $pkg->{$button_frame} = $pkg->{$mw}->Frame(-borderwidth => '8');
    $pkg->{$button_frame}->pack(-fill => 'x');
}

sub make_delete_button
{
    my ($pkg) = shift;
    my $window = shift;
    my $button_frame = 'button_frame';
    my $delete_button = 'delete_button';
    if  (defined($window)) {
	$button_frame .= $window;
	$delete_button .= $window;
    }
    unless (defined $pkg->{$button_frame}) { $pkg->_make_button_frame($window); }
    $pkg->{$delete_button} = $pkg->{$button_frame}->Button(
					      -disabledforeground     => 'purple',
#					      -fg                     => 'purple',
	                                      -state                  => 'disabled',
					      -text                   => "Delete",
					      )->pack(-side => 'left');

#    my $balloon = $pkg->{button_frame}->Balloon( -background       =>   'white');
#    $balloon->attach($pkg->{delete_button},
#		     -balloonmsg => 'Delete this plate',
#		     );

    return($pkg->{$delete_button});
}

sub make_clear_button
{
    my ($pkg) = shift;
    my $window = shift;
    my $button_frame = 'button_frame';
    my $clear_button = 'clear_button';
    if  (defined($window)) {
	$button_frame .= $window;
	$clear_button .= $window;
    }

    unless (defined($pkg->{$button_frame})) { $pkg->_make_button_frame($window); }
    $pkg->{$clear_button} = $pkg->{$button_frame}->Button(
				  	      -disabledforeground     => 'purple',
#					      -fg                     => 'black',
					      -text                   => "Clear all boxes",
					      )->pack(-side => 'left');

    my $balloon = $pkg->{$button_frame}->Balloon( -background       =>   'white');
    $balloon->attach($pkg->{$clear_button},
		     -balloonmsg => 'Clear entry boxes',
		     );

    return($pkg->{$clear_button});
}

sub make_cancel_button
{
    my ($pkg) = shift;
    my $window = shift;
    my $button_frame = 'button_frame';
    my $cancel_button = 'cancel_button';
    if  (defined($window)) {
	$button_frame .= $window;
	$cancel_button .= $window;
    }
    unless (defined($pkg->{$button_frame})) { $pkg->_make_button_frame($window); }
    $pkg->{$cancel_button} = $pkg->{$button_frame}->Button(
				  	      -disabledforeground     => 'purple',
#					      -fg                     => 'black',
					      -text                   => "Cancel",
					      )->pack(-side => 'left');

    return($pkg->{$cancel_button});
}

sub make_quit_button
{
    my ($pkg) = shift;
    my $window = shift;
    my $button_frame = 'button_frame';
    my $quit_button = 'quit_button';
    if  (defined($window)) {
	$button_frame .= $window;
	$quit_button .= $window;
    }
    unless (defined($pkg->{$button_frame})) { $pkg->_make_button_frame($window); }
    $pkg->{$quit_button} = $pkg->{$button_frame}->Button(
					    -disabledforeground     => 'purple',
#					    -fg                     => 'black',
					    -text                   => "Quit",
					    -command                => sub { _quit($pkg, $window); }
					    )->pack(-side => 'right');
    my $balloon = $pkg->{$button_frame}->Balloon( -background       =>   'white');
    $balloon->attach($pkg->{$quit_button},
		     -balloonmsg => 'Quit this screen without saving',
		     );
    return($pkg->{$quit_button});
}

sub make_update_button
{
    my ($pkg) = shift;
    my $window = shift;
    my $button_frame = 'button_frame';
    my $update_button = 'update_button';
    if  (defined($window)) {
	$button_frame .= $window;
	$update_button .= $window;
    }
    unless (defined $pkg->{$button_frame}) { $pkg->_make_button_frame($window); }
    $pkg->{$update_button} = $pkg->{$button_frame}->Button(
					      -disabledforeground     => 'purple',
	                                      -state                  => 'disabled',
					      -text                   => "Submit",
					      )->pack(-side => 'right');

    my $balloon = $pkg->{$button_frame}->Balloon( -background       =>   'white');
    $balloon->attach($pkg->{$update_button},
		     -balloonmsg => 'Store this information in the database',
		     );

    return($pkg->{$update_button});
}

sub _gotoPlate
{
	my $pkg = shift;
	$pkg->{bc_label}->focus();
	$pkg->{bc_label}->configure(-background => $pkg->{barcode_entry});
}

#
# Validate a user id scanned from a barcode.
# Returns a reference to the user object, or undef if not valid
#
sub validateUser
{
	my $pkg = shift;
	my $userId = shift;

	my $rec;

	eval {
		$rec = $pkg->{api}->getUser(-userBarcode=>$userId);
	};
	if ($@ || !defined($rec)) {
		$pkg->{status_bar}->error("Sorry, I've never heard of you");
		return undef;
	}

	# display name and email address
	my $txt = $rec->getForename() . ' (' . $rec->getEmail() . ')';
	$pkg->{login_email} = $rec->getEmail();
	$pkg->{bc_name}->configure(-text=>$txt);

	my $teams = $pkg->{api}->getTeams(-roleType=>'GENETRAP', -idPerson=>$rec->getIdPerson());
	# if there are no teams, this is an invalid person
	if (!defined($teams)) {
		$pkg->{status_bar}->error("You are not authorised to do this");
		return undef;
	}
       
	### clear error message
	$pkg->{status_bar}->show;


	# if there is one team, display it
	if (scalar @$teams == 1) {
		$pkg->{team} = $teams->[0];
                # use labelVariable rather than Label so the label updates if the team changes
		$pkg->{user_frame}->configure(-labelVariable=>\$pkg->{team}, 
                                              -labelPack => [-side=>'left', 
                                                             -after=>$pkg->{bc_name}]);
	}

	# if more than one team, display them all in a list box
	if (scalar @$teams > 1) {
		$pkg->{team} = $teams->[0];
		my $lb = $pkg->{user_frame}->BrowseEntry(-state=>'readonly', 
		                                         -browsecmd=> [\&_gotoPlate, $pkg],
		                                         -variable=>\$pkg->{team})->pack(-side=>'left');
		$lb->insert('end',@$teams);
		$lb->focus();
	}
	
	return $rec;
}

#-------------------------------------------------------------------------------------------------------#

# ask the user which electro to use if there is more than one
# takes a hash of id to code
sub selectElectro {
    my $pkg = shift;
    my %args = @_;


    # make a window asking what electro to use from the list
    # $args{-electros};
    my $electro_mw = MainWindow->new;
    $electro_mw->wm('minsize', 50, 50); 
    $electro_mw->bind('<Alt-Key-q>' => sub { exit(0); });
    $electro_mw->title('Electroporation Selection');

    my $title_frame = $electro_mw->Frame(-borderwidth => '6')->pack(-side => 'top', -fill => 'x');
    my $lb_frame = $electro_mw->Frame(-borderwidth => '6')->pack(-side => 'top', -fill => 'x');
    my $button_frame = $electro_mw->Frame(-borderwidth => '6')->pack(-side => 'top', -fill => 'x');
    
    ##### create title
    my $electro_mw_header = $title_frame->Label(-font => $pkg->{title_f},
	                                        -text => 'Electroporation Selection')->pack(-side => 'top');
    my $electro_mw_txt = $title_frame->Label(-text => "This plate contains samples from more than one electroporation.\n\nPlease select the electroporation you are working with.")->pack(-side => 'top');

    # make a pull down containing all the electro codes
    my $lb = $lb_frame->BrowseEntry(-state     => 'readonly', 
		                    -variable  => \$pkg->{electro})->pack();
    foreach my $electro(keys %{$args{-electros}}) {
	print "key $electro $args{-electros}->{$electro}\n";
        $lb->insert('end', $args{-electros}->{$electro});
	unless ($pkg->{electro}) { 
            $pkg->{electro} = $args{-electros}->{$electro}; 
        }
    }
    $lb->focus();

    # make an OK button
    my $ok_button = $button_frame->Button(-state => 'normal',
					  -text  => "OK",
                                          -command => sub { 
					      foreach my $electro(keys %{$args{-electros}}) {
						  next unless ($pkg->{electro} eq $args{-electros}->{$electro});
	                                          print "sub key $electro $args{-electros}->{$electro}\n";
						  $pkg->{id_electro} = $electro;
					      }
                                              &{$args{-callback}};
                                              $electro_mw->destroy();
                                              $args{-mw}->withdraw;
                                              $args{-mw}->deiconify;
                                          } 
                                          )->pack(-side => 'right');

#    print "$pkg->{id_electro}, $pkg->{electro}\n";
#    return ($pkg->{id_electro}, $pkg->{electro});
}

#------------------------------------------------------------------------------------------------#

sub make_window {

    my $pkg = shift;
    my %args = @_;

    my $title = $args{-title};
    my $header = $args{-header};
    my $window = $args{-window};
    my $no_clear = $args{-no_clear};

    my $entry_frame = "entry_frame" . $window;
    my $clear_button = "clear_button" . $window;
    my $cancel_button = "cancel_button" . $window;
    my $update_button = "update_button" . $window;
    my $status_bar = "status_bar" . $window;
    my $button_frame = "button_frame" . $window;
    my $mw = "mw" . $window;

    # dont make the window if it already exists
    return if ($pkg->{$mw});

    ##### define main window
    $pkg->make_mainwindow($title, $window);

    ##### display title 
    $pkg->header($header, $window);
    ##### define main window 

    $pkg->{$entry_frame} = $pkg->{$mw}->Frame()->pack(-fill => 'both');

    ######## make buttons & bind to local subs
    unless ($no_clear && ($no_clear =~ /clear/)) { $pkg->{$clear_button} = $pkg->make_clear_button($window); }
    $pkg->{$cancel_button} = $pkg->make_cancel_button($window);
    $pkg->{$update_button} = $pkg->make_update_button($window);

    unless ($no_clear && ($no_clear =~ /quit/)) { $pkg->make_quit_button($window); }

    ##### make a status bar and set it
    $pkg->{$status_bar} = $pkg->{$mw}->Status(-selfpack => 1);

    $pkg->{$status_bar}->show("Enter details");	

    # make it non-resizable
    $pkg->{$mw}->resizable(0,0);

    MainLoop(); 

}

#------------------------------------------------------------------------------------------------#

# makes columns of boxes in an entry frame in a specified window number
# @columns contains a list of references to lists of box names
# depending on the box name suffix, an entry box (e), browse entry box (e), 
# or pair of team/person boxes (lt) is made
# 
sub make_boxes { 

    my $pkg = shift;
    my $window = shift;
    my @columns = @_;

    my $box_width = 20;

    my ($column, $box_name, $box, $boxp, $boxt, $boxes_frame, $box_frame, $frame, $varp, $vart);
    my @boxes = ();
    my $all_boxes = "all_boxes" . $window;
    my $entry_frame = "entry_frame" . $window;

#    my $i = 1;

    # clear the list of boxes
    undef $pkg->{$all_boxes};

    my $main_box_frame = $pkg->{$entry_frame}->Frame()->pack(-side => 'left', -anchor => 'n');

    # for each column of boxes...
    foreach $column(@columns) {
	next unless ($column);
	@boxes = @$column;

        # make the frame for the column of boxes
        $boxes_frame = $main_box_frame->Frame(-borderwidth => 5)->pack(-side => 'left', 
                                                                       -anchor => 'n');
        # for each box...
	foreach $box_name(@boxes) {
	    $box = $box_name . '_box';

            # make a frame for the box
            $box_frame = $boxes_frame->Frame(-borderwidth => 5)->pack(-fill => 'both');

            # see if the box is an entry box, list box or team/person pair of boxes
	    if ($box_name =~ /e$/) {
	        push @{$pkg->{$all_boxes}}, $box;
                $pkg->{$box} = $box_frame->Entry(-width        => $box_width,
                                                 -state        => 'disabled',
					         -textvariable => \$pkg->{$box_name} 
					        )->pack(-side  => 'left');
	    }
	    elsif ($box_name =~ /l$/) {
	        push @{$pkg->{$all_boxes}}, $box;
                $pkg->{$box} = $box_frame->BrowseEntry(-state    => 'disabled',
		                                       -variable => \$pkg->{$box_name},
		                                       -width    => $box_width
                                                      )->pack(-side => 'left');
	    }
	    elsif ($box_name =~ /lt$/) {
		$boxp = $box . 'p';
		$boxt = $box . 't';
	        push @{$pkg->{$all_boxes}}, $boxp;
	        push @{$pkg->{$all_boxes}}, $boxt;
		$varp = $box_name . 'p';
		$vart = $box_name . 't';
                $pkg->{$boxp} = $box_frame->BrowseEntry(-state    => 'disabled',
		                                        -variable => \$pkg->{$varp},
		                                        -width    => $box_width
                                                       )->pack(-side => 'left');
                $pkg->{$boxt} = $box_frame->BrowseEntry(-state    => 'disabled',
		                                        -variable => \$pkg->{$vart},
		                                        -width    => $box_width
                                                       )->pack(-side => 'left');
	    }
	    else {
                $box_frame->configure(-height => 32);
	    }
	}
    }
}

#------------------------------------------------------------------------------------------------#

sub make_labels {

    my $pkg = shift;
    my $window = shift;
    my @left_labels = @_;

    my $labels = "labels" . $window;
    my $entry_frame = "entry_frame" . $window;

    # make the left hand label frame
    $pkg->{$labels} = $pkg->{$entry_frame}->Frame(-borderwidth => 5)->pack(-side => 'left', -fill => 'both');
    foreach (@left_labels) {
        my $label_frame = $pkg->{$labels}->Frame(-borderwidth => 5)->pack(-fill => 'both');
        $label_frame->Label(-text => $_, -pady => 2)->pack(-anchor => 'w');
    }

}

#-------------------------------------------------------------------------------------------------------#

sub disable_boxes {

    my $pkg = shift;
    my $window = shift;

    unless ($window) { $window = ""; }
    my $all_boxes = "all_boxes" . $window;
    my $clear_button = "clear_button" . $window;
    my $cancel_button = "cancel_button" . $window;
    my $update_button = "update_button" . $window;

    # disable all the boxes (submit window3 has been activated)
    foreach my $box(@{$pkg->{$all_boxes}}) {
	next unless ($pkg->{$box});
	$pkg->{$box}->configure( -state=>'disabled');
    }

    $pkg->{$clear_button}->configure(-state => 'disabled') if ($pkg->{$clear_button});
    $pkg->{$cancel_button}->configure(-state => 'disabled') if ($pkg->{$cancel_button});
    $pkg->{$update_button}->configure(-state => 'disabled') if ($pkg->{$update_button});
}

#-------------------------------------------------------------------------------------------------------#

sub fill_teams_box {

    my $pkg = shift;
    my %args = @_;

    my $team_var = $args{-type} . "_ltt";
    my $team_box = $args{-type} . "_lt_boxt";

    # populate team box
    # get all the sanger teams
    my $teams = $pkg->{api}->getTeamList();
    my @teams = @$teams;
    # populate the list box
    if ($pkg->{$team_box}) { $pkg->{$team_box}->delete(0, 'end'); }
    $pkg->{$team_box}->insert('end', 'external', 'commercial');
    foreach (@teams) {
	$pkg->{$team_box}->insert('end', $_->[0]);
    }

    # set a default (external supplier)
    unless ($pkg->{$team_var}) { 
	if ($args{-type} eq 'prepped_by') { $pkg->{$team_var} = '87'; }
	else { $pkg->{$team_var} = 'external'; }
    }
    # change focus to team box
    $pkg->{$team_box}->configure(-bg    => 'light green', 
                                 -state => 'readonly');
    $pkg->{$team_box}->focus();


}

#-----------------------------------------------------------------------------------------------#

sub fill_team_people_box {

    my $pkg = shift;
    my %args = @_;

    my $type = $args{-type};

    my $team_var = $type . "_ltt";
    my $people_var = $type . "_ltp";
    my $entry_var = $type . "_e";
    my $people_box = $type . "_lt_boxp";
    my $team_names;

    if ($type eq 'supplier') { $team_names = 'steam_names'; }
    elsif ($type eq 'designer') { $team_names = 'dteam_names'; }
    elsif ($type eq 'prepped_by') { $team_names = 'pteam_names'; }
 
    my $team = $pkg->{$team_var};
    # gets id_person, email, forename, surname 
    $pkg->{$team_names} = $pkg->{api}->getTeamPeople($team);
    # populate people box
    $pkg->{$people_var} = undef;
    $pkg->{$entry_var} = undef;
    if ($pkg->{$people_box}) { $pkg->{$people_box}->delete(0,'end'); }
    foreach (@{$pkg->{$team_names}}) {
	my $name;
	if ($_->[1]) {
	    $name = "$_->[1], $_->[2] $_->[3]";
	}
	else {
	    $name = "$_->[2] $_->[3]"; # for Robbie the robot (no email)
	}
	$pkg->{$people_box}->insert('end', $name);
	$_->[4] = $name;
    }

    unless ($args{-no_focus}) {
        # change focus to supplier_lt_boxp (person)
	$pkg->{$people_box}->configure(-bg    => 'light green', 
                                       -state => 'readonly');
	$pkg->{$people_box}->focus();
    }
}

#-----------------------------------------------------------------------------------------------#

sub fill_companies_box {

    my $pkg = shift;
    my %args = @_;

    my $type = $args{-type};

    my $name_var = $type . "_ltp";
    my $entry_var = $type . "_e";
    my $comp_box = $type . "_lt_boxp";

    if ($pkg->{type} eq 'selection') {
        $name_var = $type . "_l";
        $comp_box = $type . "_l_box";
    }

    $pkg->{all_suppliers} = $pkg->{TRAPapi}->getSuppliers();
    # populate supplier_lt_boxp
    $pkg->{$name_var} = undef;
    $pkg->{$entry_var} = undef;
    if ($pkg->{$comp_box}) { $pkg->{$comp_box}->delete(0,'end'); }
    $pkg->{$comp_box}->insert('end', 'new company');
    foreach (@{$pkg->{all_suppliers}}) {
	my $name = "$_->[1]";
	$pkg->{$comp_box}->insert('end', $name);
    }
    # change focus to supplier_lt_boxp (person)
    $pkg->{$comp_box}->configure(-bg    => 'light green', 
                                 -state => 'readonly');
    $pkg->{$comp_box}->focus();
}

#-----------------------------------------------------------------------------------------------#

sub fill_external_box {

    my $pkg = shift;
    my %args = @_;

    my $type = $args{-type};

    my $people_var = $type . "_ltp";
    my $entry_var = $type . "_e";
    my $people_box = $type . "_lt_boxp";
    my $pi_name;

    # gets...  id_user, organisation name, lab name, user name, user title, id_lab_pi
    $pkg->{external_names} = $pkg->{TRAPapi}->getExternalPeople();
    # populate people box
    $pkg->{$people_var} = undef;
    $pkg->{$entry_var} = undef;
    if ($pkg->{$people_box}) { $pkg->{$people_box}->delete(0,'end'); }
    $pkg->{$people_box}->insert('end', 'new external person');
    foreach (@{$pkg->{external_names}}) {
        # build the list box entry
	my $name;
        if ($_->[4]) { $name = "$_->[4] $_->[3], $_->[2], $_->[1]"; }
        else{ $name = "$_->[3], $_->[2], $_->[1]"; }
        # if this person is the lab pi...
	if ($_->[0] eq $_->[5]) { $name .= " (PI)"; }
	$pkg->{$people_box}->insert('end', $name);
	$_->[6] = $name;
    }
    # change focus to supplier_lt_boxp (person)
    $pkg->{$people_box}->configure(-bg    => 'light green', 
                                   -state => 'readonly');
    $pkg->{$people_box}->focus();
}

#-----------------------------------------------------------------------------------------------#

sub get_name_from_id {

    my $pkg = shift;
    my %args = @_;

    my $type = $args{-type};
    my $value = $args{-value};
    my $ori = $args{-ori};
    my $fill = $args{-fill};

    my $team_var = $type . "_ltt";
    my $person_var = $type . "_ltp";
    my $entry_var = $type . "_e";
    my $team_names;

    if ($type eq 'supplier') { $team_names = 'steam_names'; }
    elsif ($type eq 'designer') { $team_names = 'dteam_names'; }
    elsif ($type eq 'prepped_by') { $team_names = 'pteam_names'; }
   
    # if this is getting old values for confirm_submit....
    unless ($fill) {
        $team_var = "o_" . $type . "t";
        $person_var = "o_" . $type;
        $entry_var = "o_" . $type . "e";
    }

    my $team_box = $type . "_lt_boxt";
    my $person_box = $type . "_lt_boxp";
    my $entry_box = $type . "_e_box";

    if (($ori == 2) ||                    # team 87 person, value is a id_regrow
        ($ori == 3)) {                    # team 87 person, value is a id_role
        # get the id_role for the id_regrow
	if ($ori == 2) {
	    ($value) = $pkg->{TRAPapi}->getRegrowRole($value, '12');
	    print "couldnt get the role for the regrow\n";
            return(0);
	}
        # fill the team box
	if ($fill) { $pkg->fill_teams_box(-type => $type); }
        # set the team box value
	$pkg->{$team_var} = '87';
        # populate the person box
	if ($fill) { $pkg->fill_team_people_box(-type => $type); }
        # the value is an id_role
        # get the person entry
        # (do it this way rather that getting it from the team_names hash since this may change)
	my $user = $pkg->{api}->getUser(-idRole => $value);
	my $email = $user->getEmail();
	my $forename = $user->getForename();
	my $surname = $user->getSurname();
	$pkg->{$person_var} = "$email, $forename $surname";
    }
    elsif ($ori == 4) {                 # non team 87 person, value is a id_person
        # fill the team box
	if ($fill) { $pkg->fill_teams_box(-type => $type); }
        # set the team box value
        # get the team for the $value from team_person_role
	$pkg->{$team_var} = $pkg->{api}->getPersonTeam($value);
        # populate the person box
	if ($fill) { $pkg->fill_team_people_box(-type => $type); }
        # the value is an id_person
        # get the person entry
        # (do it this way rather that getting it from the team_names hash since this may change)
	my $user = $pkg->{api}->getUser(-idPerson => $value);
	my $email = $user ->getEmail();
	my $forename = $user ->getForename();
	my $surname = $user ->getSurname();
	$pkg->{$person_var} = "$email, $forename $surname";
    }
    elsif ($ori == 5) {                 # value is an id_user
        # fill the team box
	if ($fill) { $pkg->fill_teams_box(-type => $type); }
        # set the team box value
	$pkg->{$team_var} = 'external';
        # populate the person box
	if ($fill) { $pkg->fill_external_box(-type => $type); }
	foreach (@{$pkg->{external_names}}) {
	    next unless ($_->[0] == $value);
            # set the box to this
	    $pkg->{$person_var} = $_->[6];
	}
    }
    elsif ($ori == 6) {                 # value is an id_org
        # fill the team box
	if ($fill) { $pkg->fill_teams_box(-type => $type); }
        # set the team box value
	$pkg->{$team_var} = 'commercial';
        # populate the person box
	if ($fill) { $pkg->fill_companies_box(-type => $type); }
	foreach (@{$pkg->{all_suppliers}}) {
	    next unless ($_->[0] eq $value);
            # set the box to this
	    $pkg->{$person_var} = $_->[1];
	}
    }

    $pkg->{$entry_var} =  $pkg->{$person_var};

    if ($fill) { 
        $pkg->{$team_box}->configure(-bg => 'white', -state => 'readonly');
        $pkg->{$person_box}->configure(-bg => 'white', -state => 'readonly');
        $pkg->{$entry_box}->configure(-bg => 'white');
    }
}

#-----------------------------------------------------------------------------------------------#

sub get_origins {

    my $pkg = shift;
    my $type = shift;

    my $team_box = $type . "_lt_boxt";
    my $team_var = $type . "_ltt";
    my $person_var = $type . "_ltp";
    my ($id, $ori);

    return() unless ($pkg->{$team_var});

    if ($pkg->{$team_var} eq 'commercial') {
	$id = $pkg->{TRAPapi}->getOrgIdFromName($pkg->{$person_var});
	$ori = 6;
    }
    elsif ($pkg->{$team_var} eq 'external') {
	$id = $pkg->get_user_id($type);
	$ori = 5;
    }
    elsif ($pkg->{$team_var} eq '87') {
	$id = $pkg->get_role_id($type);
	$ori = 3;
    }
    else {
	$id = $pkg->get_person_id($type);
	$ori = 4;
    }

    return($id, $ori);
}

#-------------------------------------------------------------------------------------------------------#

sub get_role_id {

    my $pkg = shift;
    my $type = shift;

    my $id_person;
    my $role;

    my $team_var = $type . "_ltt";
    my $person_var = $type . "_e";
    my $team = $pkg->{$team_var};
    my $person = $pkg->{$person_var};
    my $team_names;

    if ($type eq 'supplier') { $team_names = 'steam_names'; }
    elsif ($type eq 'designer') { $team_names = 'dteam_names'; }
    elsif ($type eq 'prepped_by') { $team_names = 'pteam_names'; }

    foreach (@{$pkg->{$team_names}}) {
	next unless ($_->[4] eq $person);
	$id_person = $_->[0];
    }
    if ($id_person) { print "got id_person $id_person\n"; }

    # try to get their id_role
    if ($id_person) {
        $role = $pkg->{api}->getTrapRole($id_person, $team);
    }

    unless ($role) {
	print "failed to get role\n";
	return(0);
    }

    return($role);
}

#-------------------------------------------------------------------------------------------------------#

sub get_person_id {

    my $pkg = shift;
    my $type = shift;

    my $id_person;

    my $team_var = $type . "_ltt";
    my $person_var = $type . "_e";
    my $team = $pkg->{$team_var};
    my ($email) = ($pkg->{$person_var} =~ /^(\S+?),/);
    my $team_names;

    if ($type eq 'supplier') { $team_names = 'steam_names'; }
    elsif ($type eq 'designer') { $team_names = 'dteam_names'; }
    elsif ($type eq 'prepped_by') { $team_names = 'pteam_names'; }

    foreach (@{$pkg->{$team_names}}) {
	next unless ($_->[1] eq $email);
	$id_person = $_->[0];
    }

    return($id_person);
 }

#-------------------------------------------------------------------------------------------------------#

sub get_user_id {

    my $pkg = shift;
    my $type = shift;

    my $id_user;
    my $name;

    my $person_var = $type . "_e";
    my $entry = $pkg->{$person_var};

    foreach (@{$pkg->{external_names}}) {
        # see which entry was picked
	next unless ($_->[6] eq $entry);
        # get the user id for that entry
	$id_user = $_->[0];
    }

    return($id_user); 
}

#-------------------------------------------------------------------------------------------------------#

sub CATCH {
    my $pkg = shift;
    print "caught it\n";
    $pkg->{TRAPapi}->rollbackTrapTransaction();
    if ($pkg->{numbers} &&
        $pkg->{TRAPapi}->restoreCellLineNumbers($pkg->{electro_id}, $pkg->{count_picks})) {
        $pkg->{numbers} = undef;
    }

}

#----------------------------------------------------------------------------------------------#


1;
