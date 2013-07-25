package HTGT::Controller::Plate::Update;

use strict;
use warnings;
use base 'Catalyst::Controller';
use DateTime;
use DateTime::Format::Strptime;
use JSON;
use Regexp::Common qw /number/;
use DBD::Oracle qw(:ora_types);
use List::Util qw(max);
use List::MoreUtils qw(any);
use HTGT::Utils::Plate::AddPhaseMatchedCassette;

=head1 NAME

HTGT::Controller::Plate::Update - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

Ajax methods for updating various plate attributes

=head1 General Methods

=cut

=head2 auto

Perform authorisation - all Plate access that involves a database edit requires the 'edit' privelege

=cut

sub auto : Private {
  my ( $self, $c ) = @_;
  unless ( $c->check_user_roles('edit') ) {
    $c->flash->{error_msg} = "You are not authorised to use this function";
    $c->response->redirect( $c->uri_for('/') );
    return 0;
  }
  return 1;
}

=head2 index 

Redirected to '/plate/show_list'

=cut

sub index : Private {
  my ( $self, $c ) = @_;
  $c->response->redirect('/plate/show_list');
}

=head1 QC Helper Methods

=head2 load_qc_data_to_plate

Function to load QC data onto a given plate once Tony and co are happy with 
the data that they want to load.  For GRD/GRQ plates.

=cut

sub load_qc_data_to_plate :Local {
  my ( $self, $c ) = @_;
  
  # Check that this form hasn't shown up on a 384 well plate.
  if ( $c->req->params->{is_384} ) {
    $c->flash->{error_msg} = "Cannot perform this function on a 384 well plate!";
    $c->response->redirect( $c->uri_for( '/plate/view', { plate_id => $c->req->params->{plate_id} } ) );
    return 1;
  }
  
  # Make sure we've been given a QC Test Run ID.
  unless ( $c->req->params->{qctest_run_id} =~ /^\d+$/ ) {
    $c->flash->{error_msg} = "You must specify a QC Test Run ID to use!";
    $c->response->redirect( $c->uri_for( '/plate/view', { plate_id => $c->req->params->{plate_id} } ) );
    return 1;
  }
  
  # Fetch our plate.
  my $plate = $c->model('HTGTDB::Plate')->find({ plate_id => $c->req->params->{plate_id} });
  
  # Fetch a QC Test Result entry to sanity check that we're loading data from and onto the correct plate.
  my $qctest_result_rs = $c->model('ConstructQC::QctestResult')->search(
    {
      "qctestRun.qctest_run_id"         => $c->req->params->{qctest_run_id},
      "me.is_best_for_construct_in_run" => 1
    },
    { join => ["qctestRun"], prefetch => ['constructClone'] }
  );
  
  # We find one?
  unless ( $qctest_result_rs->count > 0 ) {
    $c->flash->{error_msg} = "Unable to find a QC Test Run for the given ID!";
    $c->response->redirect( $c->uri_for( '/plate/view', { plate_id => $c->req->params->{plate_id} } ) );
    return 1;
  }
  
  # Set some options for the data loading.
  my $qc_options = {
    qc_schema        => $c->model('ConstructQC'),
    qctest_run_id    => $c->req->params->{qctest_run_id},
    user             => $c->user->id,
    override         => $c->req->params->{override},
    ignore_well_slop => 1,
    log              => sub { $c->log->debug(shift); }
  };
  
  $plate->load_qc($qc_options);
  $c->flash->{status_msg} = "QC data loaded.";
  $c->response->redirect( $c->uri_for( '/plate/view', { plate_id => $c->req->params->{plate_id} } ) );
  return 1;
  
}

=head1 Plate Editing Methods

The following methods are used on the plate 'edit/view' page via Tablekit

=cut

=head2 _plate_comment_update

Ajax method to update a given PlateComment record.

=cut

sub _plate_comment_update : Local {
  my ( $self, $c ) = @_;

  # Catch empty entries...
  if ( $self->trim( $c->req->params->{value} ) eq "" ) {
    $c->req->params->{value} = '<span style="color: red;">You cannot enter empty values here - use the delete button to remove entries</span>';
  }
  else {

    $c->model('HTGTDB::PlateComment')->find( { plate_comment_id => $c->req->params->{id} } )->update(
      {
        plate_comment => $c->req->params->{value},
        edit_user     => $c->user->id
      }
    );
  }

  $c->res->body( $c->req->params->{value} );
}

=head2 _plate_comment_new

Ajax method to create a new entry into the PlateComments table
and return the new contents of PlateComments for a given plate.

=cut

sub _plate_comment_new : Local {
  my ( $self, $c ) = @_;

  # create a new comment...
  my $new_comment = $c->model('HTGTDB::PlateComment')->create(
    {
      plate_id      => $c->req->params->{plate_id},
      plate_comment => '[New Comment]',
      edit_user     => $c->user->id
    }
  );

  # Get the plate
  my $plate = $c->model('HTGTDB::Plate')->find( { plate_id => $c->req->params->{plate_id} }, { prefetch => 'plate_comments' } );

  $c->stash->{plate}          = $plate;
  $c->stash->{timestamp}      = $c->req->params->{timestamp};
  $c->stash->{new_comment_id} = $new_comment->plate_comment_id;
  $c->stash->{template}       = 'plate/_plate_comment_table.tt';
}

=head2 _plate_comment_delete

Ajax method to delete an entry in the PlateComments table, it will
then return the new contents of PlateComments for a given plate.

=cut

sub _plate_comment_delete : Local {
  my ( $self, $c ) = @_;

  # Look-up our plate comment
  my $plate_comment = $c->model('HTGTDB::PlateComment')->find( { plate_comment_id => $c->req->params->{plate_comment_id} } );

  # Save the id
  my $plate_id = $plate_comment->plate_id;

  # Delete the comment
  $plate_comment->delete();

  # Get the plate
  my $plate = $c->model('HTGTDB::Plate')->find( { plate_id => $plate_id }, { prefetch => 'plate_comments' } );

  $c->stash->{plate}     = $plate;
  $c->stash->{timestamp} = $c->req->params->{timestamp};
  $c->stash->{template}  = 'plate/_plate_comment_table.tt';
}

=head2 _plate_data_update

Ajax method to update a PlateData entry.

=cut

sub _plate_data_update : Local {
  my ( $self, $c ) = @_;

  # Catch empty entries...
  if ( $self->trim( $c->req->params->{value} ) eq "" ) {
    $c->req->params->{value} = '<span style="color: red;">You cannot enter empty values here - use the delete button to remove entries</span>';
  }
  else {
    $c->model('HTGTDB::PlateData')->find( { plate_data_id => $c->req->params->{id} } )->update(
      {
        $c->req->params->{field} => $c->req->params->{value},
        edit_user                => $c->user->id
      }
    );
  }

  $c->res->body( $c->req->params->{value} );
}

=head2 _plate_data_new

Ajax method to create a new entry into the PlateData table
and return the new contents of PlateData for a given plate.

=cut

sub _plate_data_new : Local {
  my ( $self, $c ) = @_;

  # Create a new data entry
  my $data_line = $c->model('HTGTDB::PlateData')->create(
    {
      plate_id   => $c->req->params->{plate_id},
      data_value => '[Enter your data value]',
      data_type  => '[Data type]',
      edit_user  => $c->user->id
    }
  );

  # Get the plate
  my $plate = $c->model('HTGTDB::Plate')->find( { plate_id => $c->req->params->{plate_id} }, { prefetch => 'plate_data' } );

  $c->stash->{plate}       = $plate;
  $c->stash->{new_data_id} = $data_line->plate_data_id;
  $c->stash->{timestamp}   = $c->req->params->{timestamp};
  $c->stash->{template}    = 'plate/_plate_data_table.tt';
}

=head2 _plate_data_delete

Ajax method to delete an entry in the PlateData table, it will
then return the new contents of PlateData for a given plate.

=cut

sub _plate_data_delete : Local {
  my ( $self, $c ) = @_;

  # Look-up our plate data row
  my $plate_data = $c->model('HTGTDB::PlateData')->find( { plate_data_id => $c->req->params->{plate_data_id} } );

  # Save the id
  my $plate_id = $plate_data->plate_id;

  # Delete the data entry
  $plate_data->delete();

  # Get the plate
  my $plate = $c->model('HTGTDB::Plate')->find( { plate_id => $plate_id }, { prefetch => 'plate_data' } );

  $c->stash->{plate}     = $plate;
  $c->stash->{timestamp} = $c->req->params->{timestamp};
  $c->stash->{template}  = 'plate/_plate_data_table.tt';
}

=head2 _plate_well_data_update_validate_params

Validate request parameters for well data update.

=cut

my %CHECKBOXES = ( 
    distribute            => [ qw( PCS PGD PGS GR GRD EPD ) ],
    pass_from_recovery_QC => [ qw( EPD ) ],
    targeted_trap         => [ qw( EPD ) ],
    primer_band_tr_pcr    => [ qw( EPD REPD ) ],
    primer_band_gf3       => [ qw( EPD REPD PIQ ) ],
    primer_band_gf4       => [ qw( EPD REPD PIQ ) ],
    primer_band_gr3       => [ qw( EPD REPD PIQ ) ],
    primer_band_gr4       => [ qw( EPD REPD PIQ ) ],
    pass_r                => [ qw( REPD ) ],
);

my %EPD_COLONY_FIELDS = map { $_ => 1 } qw( COLONIES_PICKED
                                            BLUE_COLONIES
                                            WHITE_COLONIES
                                            REMAINING_UNSTAINED_COLONIES
                                        );
                                        
my %GW_COLONY_FIELDS = map { $_ => 1 } qw( gateway_colony_number );

my %PIQ_DATE_FIELDS = map { $_ => 1 } qw( SB_pellet_date
                                          GT_pellet_date
                                          LR-PCR_pellet_date
                                          freeze_data_serum
                                          freeze_date_2i
                                        );

sub _plate_well_data_update_validate_params : Private {
    my ( $self, $c ) = @_;
    
    my $well_id    = $c->req->param( 'id' );
    my $data_type  = $c->req->param( 'field' );
    my $data_value = $c->req->param( 'value' );
    
    die "well id not specified\n"
        unless defined $well_id;
 
    die "data type not specified\n"
        unless  defined $data_type;
    
    $data_value = '-'
        unless defined $data_value and $data_value =~ /\S/;
    
    my $strp_date = DateTime::Format::Strptime->new( pattern => '%d/%m/%y' );
    foreach ( $well_id, $data_type, $data_value ) {
        # trim leading and trailing whitespace
        s/^\s+|\s+$//g;
    }
    
    my $well = $c->model('HTGTDB::Well')->find( { well_id => $well_id }, { prefetch => 'plate' } )
        or die "well $well_id not found\n";
    
    if ( $CHECKBOXES{ $data_type } ) {
        die "illegal value for $data_type: '$data_value'\n"
            unless $data_value eq '-' or $data_value eq 'yes';
        my $plate_type = $well->plate->type;
        die "$data_type is not a valid checkbox for plates of type $plate_type\n"
            unless grep { $plate_type eq $_ } @{ $CHECKBOXES{ $data_type } };
    }
    elsif ( $EPD_COLONY_FIELDS{ $data_type } or $GW_COLONY_FIELDS{ $data_type } ) {
        die "illegal value for $data_type: '$data_value'\n"
            unless $data_value eq '-'
                 or ( $data_value =~ $RE{num}{int} and $data_value >= 0 );
    }
    elsif ( $PIQ_DATE_FIELDS{ $data_type } ) {
        if ( $data_value ne '-' && !$strp_date->parse_datetime($data_value) ) {
            die "illegal date value: $data_value, must be in format dd/mm/yy\n";
        }
    }
        
    my $well_desc = sprintf( '%s[%s]', $well->plate->name, $well->well_name );
    
    return ( $well_id, $well_desc, $data_type, $data_value );
}

=head2 _do_well_data_update

Helper function to do the actual database update.  Should be called inside an enclosing txn_do().

=cut

sub _do_well_data_update : Private {
    my ( $self, $c, $well_id, $data_type, $data_value ) = @_;
    
    if ( $data_value eq '-' ) {
        my $well_data = $c->model('HTGTDB::WellData')->find(
            {   well_id   => $well_id, 
                data_type => $data_type
            }
        );
        if ( $well_data ) {
            $well_data->delete();
        }
    }
    else {
        $c->model('HTGTDB::WellData')->update_or_create(
            {   well_id    => $well_id,
                data_type  => $data_type,
                data_value => $data_value,
                edit_user  => $c->user->id,
                edit_date  => \"current_timestamp"
            }
        );
    }
}

=head2 _plate_well_data_update

Ajax method used by TableKit to update the well_data values on the 
'plate/view' page

=cut

sub _plate_well_data_update : Local {
    my ( $self, $c ) = @_;

    $c->log_request();

    my ( $well_id, $well_desc, $data_type, $data_value )
        = eval { $self->_plate_well_data_update_validate_params( $c ) };
        
    if ( my $err = $@ ) {
        $c->audit_error( $err );
        $c->response->body( "<span style='color: red;'>$err</span>" );
        $c->response->status( 400 );
        return;
    }
    
    $c->audit_info( "$well_desc set $data_type => $data_value" );

    eval {    
        $c->model('HTGTDB')->schema->txn_do( sub {
            $self->_do_well_data_update( $c, $well_id, $data_type, $data_value );
            if ( $EPD_COLONY_FIELDS{ $data_type } ) {
                my $total_colonies = 0;
                foreach my $colony_type ( keys %EPD_COLONY_FIELDS ) {
                    my $count = $c->model('HTGTDB::WellData')->find(
                        {   well_id   => $well_id,
                            data_type => $colony_type
                        }
                    );
                    if ( $count and $count->data_value ) {
                        $total_colonies += $count->data_value;
                    }                                   
                }
                $c->audit_info( "$well_desc set TOTAL_COLONIES => $total_colonies" );
                $self->_do_well_data_update( $c, $well_id, 'TOTAL_COLONIES', $total_colonies );
            }
        } );
    };
   
    if ( my $err = $@ ) {
        $c->audit_error( $err );
        $c->response->body( "<span style='color: red;'>$err</span>" );
        $c->response->status( 500 );
        return; 
    }

    # Here follows the most unholy of hacks... - remember where you read this one first! ;)
    # Return the new data value in the response body; if the data value is '0', prefix
    # with a space lest Catalyst assume a null body and attempt to render via a template

    if ( $data_value eq '0' ) {
        $c->response->body( ' 0' );
    }
    else {
        $c->response->body( $data_value );
    }
  
    $c->audit_info( "$well_desc update COMMITTED" );
    
}

=head2 _update_all_well_data

Ajax method to update ALL of the well_data entries (of a 
given data_type) on a plate.

=cut

sub _update_all_well_data : Local {
  my ( $self, $c ) = @_;

  my $plate = $c->model('HTGTDB::Plate')->find( { plate_id => $c->req->params->{plate_id} } );

  my $dt        = DateTime->now;
  my $date      = $dt->day . '-' . $dt->month_name . '-' . $dt->year;
  my $timestamp = $dt->strftime("%F %r");
  my $response  = '<span class="success"><em>Saved (' . $timestamp . ')</em></span>';

  eval {
    foreach my $well ( $plate->wells )
    {

      # Allows us the ability to define 'only update this well if this
      # value has been set'...

      $c->log->debug( "Workin' on " . $well->well_name );

      if ( defined $c->req->params->{check_for} ) {
        my $test = $c->req->params->{check_for};
        if ( defined $well->$test ) {

          my $well_data = $c->model('HTGTDB::WellData')->find(
            {
              well_id   => $well->well_id,
              data_type => $c->req->params->{data_type}
            },
            { key => 'well_id_data_type' }
          );

          if ( defined $well_data ) {

            $c->log->debug(" - Found well data");

            $well_data->update(
              {
                data_value => $c->req->params->{data_value},
                edit_user  => $c->user->id,
                edit_date  => $date
              }
            );

          }
          else {

            $c->log->debug(" - NOT found well data");

            $c->model('HTGTDB::WellData')->create(
              {
                well_id    => $well->well_id,
                data_type  => $c->req->params->{data_type},
                data_value => $c->req->params->{data_value},
                edit_user  => $c->user->id,
                edit_date  => $date
              },
              { key => 'well_id_data_type' }
            );

          }

        }
      }
      else {

        my $well_data = $c->model('HTGTDB::WellData')->find(
          {
            well_id   => $well->well_id,
            data_type => $c->req->params->{data_type}
          },
          { key => 'well_id_data_type' }
        );

        if ( defined $well_data ) {

          $well_data->update(
            {
              data_value => $c->req->params->{data_value},
              edit_user  => $c->user->id,
              edit_date  => $date
            }
          );

        }
        else {

          $c->model('HTGTDB::WellData')->create(
            {
              well_id    => $well->well_id,
              data_type  => $c->req->params->{data_type},
              data_value => $c->req->params->{data_value},
              edit_user  => $c->user->id,
              edit_date  => $date
            },
            { key => 'well_id_data_type' }
          );

        }

      }

    }
  };

  if ($@) {
    $response = '<span class="failure"><strong>ERROR:</strong> ' . $@ . ', please resubmit.</span>';
  }

  $c->res->body($response);
}

=head2 plate_blob_new

Method to add a PlateBlob (file attachment) into the database. 
These entries are linked to plates.

=cut

sub plate_blob_new : Local {
  my ( $self, $c ) = @_;

  # Set a 2Mb file-size limit
  my $size_limit = ( ( 1024 * 1024 ) * 2 );

  # Check the file size...
  if ( $c->request->uploads->{file}->size > $size_limit ) {

    $c->flash->{error_msg} =
'Sorry, your file is too large to be stored in the database.  (The storage limit is currently 2Mb).<br/>If you need to store this file, please email <a href="mailto:htgt@sanger.ac.uk">htgt@sanger.ac.uk</a> for help.';
    $c->response->redirect( $c->uri_for( '/plate/view', { plate_id => $c->req->params->{plate_id} } ) );
    return 1;

    # Also, refuse to store BMP/TIFF/XPM images - they're a pain!!!
  }
  elsif ( $c->request->uploads->{file}->type =~ /bmp|tiff|xpm/i ) {

    $c->flash->{error_msg} = "Sorry, we cannot store this image type - please convert it to either a JPEG or PNG and resubmit.";
    $c->response->redirect( $c->uri_for( '/plate/view', { plate_id => $c->req->params->{plate_id} } ) );
    return 1;

  }
  else {

    # Check the is_public flag
    my $is_public = undef;
    if ( $c->req->params->{is_public} eq 'on' ) { $is_public = 1; }

    # Sort out the filenames passed over by bloody IE (full path-names, WTF???)...
    my $filename = $c->request->uploads->{file}->filename;
    if ( $filename =~ /^\D\:\\.*\\(.+\.\w+)$/ ) { $filename = $1; }

    # Enter the info into teh database
    $c->model('HTGTDB')->schema->txn_do(
      sub {
        eval {
          my $plate_blob = $c->model('HTGTDB::PlateBlob')->update_or_create(
            {
              plate_id         => $c->req->params->{plate_id},
              description      => $c->req->params->{description},
              is_public        => $is_public,
              binary_data_type => $c->request->uploads->{file}->type,
              file_name        => $filename,
              file_size        => $c->request->uploads->{file}->size,
              edit_user        => $c->user->id
            },
            { key => 'plate_id_file_name' }
          );

          my $dbh = $c->model('HTGTDB')->storage->dbh;
          my $sth = $dbh->prepare('UPDATE PLATE_BLOB SET binary_data = ? WHERE plate_blob_id = ?');
          $sth->bind_param( 1, $c->request->uploads->{file}->slurp, { ora_type => ORA_BLOB, ora_field => 'binary_data' } );
          $sth->bind_param( 2, $plate_blob->plate_blob_id );
          $sth->execute();

          # Create a thumbnail of an image...
          if ( $c->request->uploads->{file}->type =~ /image/ ) {
            use GD;
            use GD::Image::Thumbnail;

            my $image = GD::Image->new( $c->request->uploads->{file}->fh );
            my $thumbnail = $image->thumbnail( { side => '50' } );

            my $sth = $dbh->prepare('UPDATE PLATE_BLOB SET image_thumbnail = ? WHERE plate_blob_id = ?');
            $sth->bind_param( 1, $thumbnail->png, { ora_type => ORA_BLOB, ora_field => 'image_thumbnail' } );
            $sth->bind_param( 2, $plate_blob->plate_blob_id );
            $sth->execute();
          }
        };
        if ($@) {
          $c->flash->{error_msg} = "Error uploading your file - please resubmit your request";
          $c->response->redirect( $c->uri_for( '/plate/view', { plate_id => $c->req->params->{plate_id} } ) );
          return 1;
        }
      }
    );

  }

  $c->flash->{status_msg} = "File '" . $c->request->uploads->{file}->filename . "' saved";
  $c->response->redirect( $c->uri_for( '/plate/view', { plate_id => $c->req->params->{plate_id} } ) );
  return 1;
}

=head2 _plate_blob_update

Ajax method used by TableKit to update the file attachment details on the 
'plate/view' page

=cut

sub _plate_blob_update : Local {
  my ( $self, $c ) = @_;

  my $plate_blob_id = $c->req->params->{id};
  $plate_blob_id =~ s/plateblob//;

  my $plate_blob = $c->model('HTGTDB::PlateBlob')->find( { plate_blob_id => $plate_blob_id } );
  $plate_blob->update( { $c->req->params->{field} => $c->req->params->{value} } );

  if ( $c->req->params->{field} eq 'is_public' ) {
    if   ( $c->req->params->{value} eq '0' ) { $c->res->body('<img src="/icons/silk/stop.png" alt="not public" />'); }
    else                                     { $c->res->body('<img src="/icons/silk/accept.png" alt="public" />'); }
  }
  else {
    $c->res->body( $c->req->params->{value} );
  }
}

=head2 _plate_blob_delete

Ajax method to delete an entry in the PlateBlob table, it will
then return the 'Plate' object for a given plate.

=cut

sub _plate_blob_delete : Local {
  my ( $self, $c ) = @_;

  my $plate_blob = $c->model('HTGTDB::PlateBlob')->find( { plate_blob_id => $c->req->params->{plate_blob_id} } );

  # Save the plate_id
  my $plate_id = $plate_blob->plate_id;

  # Delete the blob entry
  $plate_blob->delete();

  # Get the remaining plat blobs
  my @plate_blobs = $c->model('HTGTDB::PlateBlob')->search(
    { plate_id => $plate_id },
    {
      columns =>
       [ 'plate_blob_id', 'plate_id', 'binary_data_type', 'image_thumbnail', 'file_name', 'file_size', 'description', 'is_public', 'edit_user', 'edit_date' ]
    }
  );

  $c->stash->{plate_blobs} = \@plate_blobs;
  $c->stash->{timestamp}   = $c->req->params->{timestamp};
  $c->stash->{template}    = 'plate/_plate_attachments_table.tt';
}

=head1 Nanodrop Processing Methods

=cut

=head2 nanodrop_process

Background processing of Nanodrop files.  Requires a nanodrop file upload (from 
the 'nanodrop' method), and a plate_id/name to associate all of the data to.  The 
resulting data is placed in the 'well_data' table.

INPUT: plate_id (optional), plate_name and nanodrop input file.

=cut

sub nanodrop_process : Local {
  my ( $self, $c ) = @_;

  # Check for input fields
  unless ( $c->req->params->{plate_name} && $c->request->uploads->{file} ) {
    $c->flash->{error_msg} = "All fields are required.  Please resubmit your request.";
    $c->response->redirect( $c->uri_for('/plate/nanodrop') );
    return;
  }

  # See if the plate exists already - if not, create it...
  my $plate_id;
  if ( $c->req->params->{plate_id} ) {

    # We've got an ID from the autocompleter already
    $plate_id = $c->req->params->{plate_id};
  }
  else {

    # Look the plate up
    my $plate = $c->model('HTGTDB::Plate')->find(
      {
        name => $c->req->params->{plate_name},
        type => $c->req->params->{plate_type}
      },
      { key => 'plate_name_type' }
    );

    # If the plate exists - update it
    # If the plate doesn't exist - create it
    my $dt   = DateTime->now;
    my $date = $dt->day . '-' . $dt->month_name . '-' . $dt->year;

    if ($plate) {
      $plate->update(
        {
          edited_user => $c->user->id,
          edited_date => $date
        }
      );
    }
    else {
      $plate = $c->model('HTGTDB::Plate')->create(
        {
          name         => $c->req->params->{plate_name},
          type         => $c->req->params->{plate_type},
          created_user => $c->user->id,
          created_date => $date
        }
      );
    }

    # Finally - make the plate_id usable later in this method
    $plate_id = $plate->plate_id;
  }

  # Read in our file and watch for errors
  my $upload;
  my @fileconts;
  eval {
    $upload = $c->request->uploads->{file};
    @fileconts = split "\n", $upload->slurp;
  };
  if ($@) {
    $c->flash->{error_msg} = "Error uploading your file.  Please resubmit your request.";
    $c->response->redirect( $c->uri_for('/plate/nanodrop') );
    return;
  }

  my @header = split "\t", shift(@fileconts);
  my $well_pos;
  my $ng_pos;

  # Extract the positions of the Well and ng/ul columns
  for ( my $i = 0 ; $i < scalar(@header) ; $i++ ) {
    if    ( $header[$i] =~ /Well/ )   { $well_pos = $i; }
    elsif ( $header[$i] =~ /ng\/ul/ ) { $ng_pos   = $i; }
    else                              { next; }
  }

  # Move through the file and extract the information we need
  my %data;
  foreach (@fileconts) {
    if    ( $_ =~ /^Sample/ ) { last; }
    elsif ( $_ =~ /^\s*$/ )   { next; }
    else {
      my @line = split "\t", $_;

      # Format our well name correctly
      if ( $line[$well_pos] =~ /^(\D)(\d{1})$/ ) {
        $line[$well_pos] = $1 . '0' . $2;
      }

      # Calculate the details the lab needs
      my $vol_dna;
      if   ( ( 5000 / $line[$ng_pos] ) > 70 ) { $vol_dna = 70; }
      else                                    { $vol_dna = ( 5000 / $line[$ng_pos] ); }

      my $ug_dna    = ( $line[$ng_pos] * $vol_dna ) / 1000;
      my $vol_mix   = 13;
      my $vol_water = 100 - $vol_dna - $vol_mix;

      $data{ $line[$well_pos] } = {
        'ng_ul'     => $line[$ng_pos],
        'ug_dna'    => $ug_dna,
        'vol_dna'   => $vol_dna,
        'vol_water' => $vol_water,
        'vol_mix'   => $vol_mix,
      };
    }
  }

  # Set-up a shortcut for entering the well data values
  my %data_values = (
    'ng_ul'     => 'NG_UL_DNA',
    'ug_dna'    => 'UG_DNA',
    'vol_dna'   => 'VOL_DNA',
    'vol_water' => 'VOL_WATER',
    'vol_mix'   => 'VOL_MIX',
  );

  # Get the default well names for our plate type
  my @plate_wells = HTGTDB::Plate::get_default_well_names( $c->req->params->{plate_type} );

  # Use these to enter our wells
  foreach my $well_name (@plate_wells) {
    $c->log->debug( "NANODROP - WellName: " . $well_name );

    # First, see if the well exists - if not create it...
    my $well = $c->model('HTGTDB::Well')->find(
      {
        plate_id  => $plate_id,
        well_name => [ $well_name, $c->req->params->{plate_name} . '_' . $well_name ],
      },
      { key => 'plate_id_well_name' }
    );

    # Well naming...  If PGD plates - just plain old A01, B01 etc.
    # If GRD plates - GRD0001_A01, GRD0001_B01 etc. (for now!)

    if ( defined $well ) {

      # Nothing to see here, move along...
    }
    else {

      if ( $c->req->params->{plate_type} eq 'PGD' ) {
        $well = $c->model('HTGTDB::Well')->create(
          {
            plate_id  => $plate_id,
            well_name => $well_name,
          }
        );
      }
      else {
        $well = $c->model('HTGTDB::Well')->create(
          {
            plate_id  => $plate_id,
            well_name => $c->req->params->{plate_name} . '_' . $well_name,
          }
        );
      }
    }

    # Now enter the nanodrop information into the well_data table
    foreach my $data_type ( keys %data_values ) {
      $well->well_data->update_or_create(
        {
          data_type  => $data_values{$data_type},
          data_value => $data{$well_name}->{$data_type},
        }
      );
    }

  }

  $c->flash->{status_msg} = 'Completed upload and processing of "' . $upload->filename . '"';
  $c->response->redirect( $c->uri_for('/plate/view') . '?plate_id=' . $plate_id );
}

=head1 Plate Creation Methods

=cut

=head2 _save_new_plate

Method to be used via an Ajax call to save a plate done on the 'plate/create' page.

INPUT:  plate_name, plate_type, plate_lock (optional), plate_desc (optional), piq_location (optional)
        plate_data - JSON object containing:
            well_name
                - parent_plate_name (optional)
                - parent_plate_id
                - parent_well_name (optional)
                - parent_well_id

=head2 save384

Method to create a 384 well plate as a collection of 96 well plates.

INPUT:  parent_plate (name), child_plate (name prefix), child_plate_type,
        number of replicates (typically 4 - single 384 or 8 - two 384 plates),
        cassette, backbone

Redirects to /plate/create384 on completion.

=cut

sub _save_new_plate : Local {
  my ( $self, $c ) = @_;

  # First, set up the success response (if anything goes wrong we change this)
  my $dt        = DateTime->now;
  my $timestamp = $dt->strftime("%F %r");
  my $response  = '<span class="success"><em>Plate Saved (' . $timestamp . ')</em></span>';
  my $date      = $dt->day . '-' . $dt->month_name . '-' . $dt->year;

  # Set an error flag
  my $error = 0;

  # Now, let's see if this plate exists,
  my $plate = HTGT::Controller::Plate->find( $c, {} );

  # Set the 'is_locked' information
  my $plate_lock;
  if   ( $c->req->params->{plate_lock} eq 'on' ) { $plate_lock = 'y'; }
  else                                           { $plate_lock = 'n'; }

  # If the plate doesn't exist - create it...
  # If it does exist, check that it isn't locked first,
  # then update the 'edited' information...
  if ($plate) {
    if ( $plate->is_locked eq 'y' ) {

      # The plate is locked - stop everything else...
      $response = '<span class="failure">' . 'Not Saved. This plate already exists and is locked' . '</span>';
      $error    = 1;
    }
    else {
      $plate->update(
        {
          edited_user => $c->user->id,
          edited_date => $date,
          description => $c->req->params->{plate_desc},
          is_locked   => $plate_lock
        }
      );
    }
  }
  else {
    $plate = $c->model('HTGTDB::Plate')->create(
      {
        name         => $c->req->params->{plate_name},
        type         => $c->req->params->{plate_type},
        description  => $c->req->params->{plate_desc},
        created_user => $c->user->id,
        created_date => $date,
        is_locked    => $plate_lock
      }
    );
  }

  # If the plate is an EP plate - auto create a PlateData entry for the 'es_cell_line'
  # to prompt Wendy and co to enter it...

  if ( $plate->type eq 'EP' ) {

    # First look to see if this is already there...
    my $plate_data = $c->model('HTGTDB::PlateData')->find( { plate_id => $plate->plate_id, data_type => 'es_cell_line' }, { key => 'plate_id_data_type' } );

    unless ( defined $plate_data ) {
      $plate_data = $c->model('HTGTDB::PlateData')->create(
        {
          plate_id   => $plate->plate_id,
          data_type  => 'es_cell_line',
          data_value => '[Enter your data value]'
        },
        { key => 'plate_id_data_type' }
      );
    }

  }

  # Now we move onto the wells...

  # Check for any errors from the plate insertion/update first
  unless ( $error == 1 ) {

    # Give a link to the new plate...
    $response .= ' -- <a href="' . $c->uri_for('/plate/view') . '?plate_id=' . $plate->plate_id . '" class="plate_link">view plate</a>';

    # Add some extra prompts if we're dealing with EP plates (for plate_data etc.)...
    if ( $plate->type eq 'EP' ) {
      $response .= q[
                <p><span style="color:red;font-size:0.9em;">
                    <strong>NOTE:</strong> Please don't forget to add the following plate data:
                    <ul>
                        <li style="color:red;">Cell line and passage number</li>
                        <li style="color:red;">Number of cells per EP</li>
                        <li style="color:red;">Electroporation details (ms)</li>
                        <li style="color:red;">Observations</li>
                    </ul>
                </span></p>
            ];
    }

    # Get the JSON data from the table
    my $plate_data = from_json( $c->req->params->{plate_data} );

    # Go through the $plate_data and enter into the db
    foreach ( sort keys %{$plate_data} ) {

      # If we have parent well links, look up the parent well so
      # we can inherit the parents design instance id
      my $new_well;

      if ( $plate_data->{$_}->{parent_well_id} ne "" ) {
        my $parent_well = $c->model('HTGTDB::Well')->find( { well_id => $plate_data->{$_}->{parent_well_id} } );

        $new_well = $c->model('HTGTDB::Well')->update_or_create(
          {
            plate_id       => $plate->plate_id,
            well_name      => $_,
            parent_well_id => $parent_well->well_id,
            edit_user      => $c->user->id,
            edit_date      => $date,
          },
          { key => 'plate_id_well_name' }
        );

        # Inherit the parent wells design_instance_id
        eval { $new_well->update( { design_instance_id => $parent_well->design_instance_id } ); };

        # Inherit the parent wells targeting cassette information
        my $cassette_data = $parent_well->well_data->find( { data_type => 'cassette' } );
        eval { $new_well->well_data->update_or_create( { data_value => $cassette_data->data_value, data_type => 'cassette' }, { key => 'well_id_data_type' } ); };

        # Inherit the parent wells plasmid backbone information
        my $backbone_data = $parent_well->well_data->find( { data_type => 'backbone' } );
        eval { $new_well->well_data->update_or_create( { data_value => $backbone_data->data_value, data_type => 'backbone' }, { key => 'well_id_data_type' } ); };

        # Update the 'PlatePlate' table to link the two plates
        $c->model('HTGTDB::PlatePlate')->find_or_create(
          {
            parent_plate_id => $plate_data->{$_}->{parent_plate_id},
            child_plate_id  => $plate->plate_id
          }
        );

        # If this is a RS (recovery set) 'plate', set the
        # 'pcs_growth' well_data value to 'yes'
        if ( $plate->type eq 'RS' ) {
          $new_well->well_data->update_or_create( { data_value => 'yes', data_type => 'pcs_growth' }, { key => 'well_id_data_type' } );
        }

        # if this is a PGS plate, copy across any PG clone and QC information
        if ( $plate->type eq 'PGS' || $plate->type eq 'PGD' ) {

          my $clone_data = $parent_well->well_data->find( { data_type => 'clone_name' } );
          eval { $new_well->well_data->update_or_create( { data_value => $clone_data->data_value, data_type => 'clone_name' }, { key => 'well_id_data_type' } ); };

          my $pass_level_data = $parent_well->well_data->find( { data_type => 'pass_level' } );
          eval {
            $new_well->well_data->update_or_create( { data_value => $pass_level_data->data_value, data_type => 'pass_level' }, { key => 'well_id_data_type' } );
          };

          my $qc_id_data = $parent_well->well_data->find( { data_type => 'qctest_result_id' } );
          eval {
            $new_well->well_data->update_or_create( { data_value => $qc_id_data->data_value, data_type => 'qctest_result_id' }, { key => 'well_id_data_type' } );
          };

        }
        # if PIQ plate add auto-incremented lab number if well does not already have lab number set
        if ( $plate->type eq 'PIQ' and !$new_well->well_data_value('lab_number') ) {
            my $lab_number = $self->create_PIQ_lab_number($c);
            if ( $lab_number ) {
                eval {  
                    $new_well->well_data->update_or_create( { data_value => $lab_number , data_type => 'lab_number' }, { key => 'well_id_data_type' } );
                };
            }
        }

      }
      else {
        $new_well = $c->model('HTGTDB::Well')->update_or_create(
          {
            plate_id  => $plate->plate_id,
            well_name => $_,
            edit_user => $c->user->id,
            edit_date => $date,
          },
          { key => 'plate_id_well_name' }
        );
      }
    }
  }

  $c->res->body($response);
}

sub save384 : Local {
  my ( $self, $c ) = @_;

  # Set the timestamp for all entries...

  my $dt   = DateTime->now;
  my $date = $dt->day . '-' . $dt->month_name . '-' . $dt->year;

  # First look up the parent plate - also get its wells

  my $parent_plate_rs = $c->model('HTGTDB::Plate')->search( { name => $c->req->params->{parent_plate} }, { prefetch => ['wells'] } );

  my @parent_plates = $parent_plate_rs->all();
  my $parent_plate;

  if ( scalar(@parent_plates) > 1 || scalar(@parent_plates) == 0 ) {
    $c->flash->{error_msg} = "Error finding your parent plate (" . $c->req->params->{parent_plate} . ") - please resubmit your request";
    $c->response->redirect( $c->uri_for('/plate/create384') );
    return 1;
  }
  else {
    $parent_plate = $parent_plates[0];
  }

  # Pre-store all of the parent plates wells (as DBIx sometimes has issues
  # with going over a resultset more than once)

  my @parent_wells = $parent_plate->wells();

  # Then check that the child plate(s) do not already exist - if yes, barf out

  my $child_plate_prefix = $c->req->params->{child_plate};
  my @child_plate_names;
  my $child_plates = {};

  my $first_replicate = $c->req->params->{first_replicate} || 1;
  my $num_replicates  = $c->req->params->{no_replicates} || 4;
  
  for ( my $i = $first_replicate; $i < ( $first_replicate + $num_replicates ); $i++ ) {
    push( @child_plate_names, $child_plate_prefix . "_" . $i );
  }

  my $child_plate_rs = $c->model('HTGTDB::Plate')->search( { name => \@child_plate_names } );

  if ( $child_plate_rs->count() > 0 ) {
    $c->flash->{error_msg} = "Sorry, some/all of your child plates have already been created. These will need to be checked and created manually.";
    $c->response->redirect( $c->uri_for('/plate/create384') );
    return 1;
  }

  # Generate the child plates one at a time, but do the whole lot in
  # a single transaction to stop any half-created plates etc clogging
  # up the system.

  my $is_error;  
  
  $c->model('HTGTDB')->schema->txn_do(
    sub {
      eval {

        foreach my $child_plate_name (@child_plate_names) {

          # Generate the plate itself
          my $child_plate = $c->model('HTGTDB::Plate')->create(
            {
              name         => $child_plate_name,
              type         => $c->req->params->{child_plate_type},
              created_user => $c->user->id,
              created_date => $date,
              edited_user  => $c->user->id,
              edited_date  => $date
            }
          );

          # Store the child plate for reporting back to the user
          $child_plates->{$child_plate_name} = $child_plate;

          # Update the 'PlatePlate' table to link the two plates
          $c->model('HTGTDB::PlatePlate')->find_or_create(
            {
              parent_plate_id => $parent_plate->plate_id,
              child_plate_id  => $child_plate->plate_id
            }
          );

          # Add a bit of plate data to indicate this plate is part
          # of a 384 well plate
          my $child_plate_data = $c->model('HTGTDB::PlateData')->create(
            {
              plate_id   => $child_plate->plate_id,
              data_type  => 'is_384',
              data_value => 'yes',
              edit_user  => $c->user->id,
              edit_date  => $date
            },
            { key => 'plate_id_data_type' }
          );

          # Now generate the wells
          foreach my $parent_well (@parent_wells) {

            my $child_well = $c->model('HTGTDB::Well')->create(
              {
                plate_id           => $child_plate->plate_id,
                parent_well_id     => $parent_well->well_id,
                well_name          => $parent_well->well_name,
                design_instance_id => $parent_well->design_instance_id,
                edit_user          => $c->user->id,
                edit_date          => $date
              },
              { key => 'plate_id_well_name' }
            );
            
            # Add in the cassette and backbone if they were set
            
            if ( $c->req->params->{cassette} ne '-' ) {
              $child_well->well_data->update_or_create(
                { data_value => $c->req->params->{cassette}, data_type => 'cassette' },
                { key => 'well_id_data_type' }
              );
            }
            
            if ( $c->req->params->{backbone} ne '-' ) {
              $child_well->well_data->update_or_create(
                { data_value => $c->req->params->{backbone}, data_type => 'backbone' },
                { key => 'well_id_data_type' }
              );
            }
            
          }
          
          # Finally, load in the QC results from the QC system
          if ( $c->req->params->{load_qc} eq 'yes' ) {
            my $options = {
              qc_schema => $c->model('ConstructQC'),
              user      => $c->user->id,
              #log       => sub{ $c->log->debug(shift); }
            };
            $child_plate->load_384well_qc( $options );
          }
          
        }

      };

      if ($@) {
        $c->model('HTGTDB')->schema->txn_rollback;
        $c->log->error( "Failed to create plates: $@" );
        $is_error = 1;        
      }
      else {
        $c->model('HTGTDB')->schema->txn_commit;
      }

    }
  );

  if ( $is_error ) {
      $c->flash->{error_msg} = "Error creating your plates - please resubmit your request";
      $c->response->redirect( $c->uri_for('/plate/create384') );
      return 1;
  }
  
  # If we got here all went well! Finish off - woop woop!
  my $message = "Your plates were sucessfully created:<br /><ul>\n";
  foreach my $plate (@child_plate_names) {
    $message .= "<li>" . $child_plates->{$plate}->name . " - ";
    $message .= '<a href="' . $c->uri_for('/plate/view') . '?plate_id=' . $child_plates->{$plate}->plate_id . '" class="plate_link">view plate</a>';
    $message .= "</li>\n";
  }
  $message .= "</ul>";

  $c->flash->{status_msg} = $message;
  $c->response->redirect( $c->uri_for('/plate/create384') );
  return 1;
}

sub save_from_file :Local {
  my ( $self, $c ) = @_;

  # Set the timestamp for all entries...
  my $dt   = DateTime->now;
  my $date = $dt->day . '-' . $dt->month_name . '-' . $dt->year;
  
  # Read in the data...
  my @csv_data = split( "\n", $c->req->params->{csv_data} );
  unless ( scalar(@csv_data) == 96 ) {
    $c->flash->{error_msg} = "You have not described 96 wells - please resubmit";
    $c->response->redirect( $c->uri_for('/plate/create') );
    return;
  }
  
  ##
  ## There are two modes of operation...
  ##  - Tony/Stefania mode, mapping new wells to existing clones
  ##  - Other mode, working off plate/well mappings
  ##
  
  my $new_plate_map = [];
  
  # Tony/Stefania mode...
  if ( $c->req->params->{csv_file_layout} eq 'plate_well_clone' ) {
    
    foreach my $row ( @csv_data ) {
      $row =~ s/\n//;
      my @well_info = split( ",", $row );
      
      # Parse the clone name into a HTGT plate/well
      $well_info[2] =~ /(\w+)_(\w{1})_(\w{3})_(\d+)/;
      my $plate = $1;
      my $clone = $2;
      my $well  = $3;
      my $iter  = $4;
      
      # Set up the parent placeholders...
      my $parent_plate = $plate . '_' . $clone . '_' . $iter;
      my $parent_well  = $well ? $well : undef;
      
      # If we have a PC clone, doctor the plate name...
      if ( $plate =~ /^PC/ ) {
        $parent_plate =~ s/PC/PCS/;
      }
      
      push( @{$new_plate_map}, {
        child_plate  => $well_info[0],
        child_well   => $well_info[1],
        parent_plate => $parent_plate,
        parent_well  => $parent_well
      });
      
    }
    
  }
  # Other mode...
  else {
    
    foreach my $row ( @csv_data ) {
      $row =~ s/\s//g;
      my @well_info = split( ",", $row );
      
      push( @{$new_plate_map}, {
        child_plate  => $well_info[0],
        child_well   => $well_info[1],
        parent_plate => $well_info[2],
        parent_well  => $well_info[3]
      });
    }
    
  }
  
  # Now check that all of the parent plates exist before creating stuff...
  my %parent_plates = ();
  foreach my $p ( @{$new_plate_map} ) {
    if ( defined $p->{parent_plate} && $p->{parent_plate} ne "" ) {
      $parent_plates{ $p->{parent_plate} } = "";
    }
  }
  my $parent_plate_check_rs = $c->model('HTGTDB::Plate')->search({ name => [ keys %parent_plates ] });
  if ( $parent_plate_check_rs->count() != scalar( keys %parent_plates ) ) {
    $c->flash->{error_msg} = "Sorry, one of your parent plates is missing - please create the parent plates first then resubmit";
    $c->response->redirect( $c->uri_for('/plate/create') );
    return;
  }
  
  # Fine, if we get this far, the parents exist, now to create the plates/wells...
  my %plates_made = ();
  
  $c->model('HTGTDB')->schema->txn_do(
    sub {
      
      foreach my $map ( @{$new_plate_map} ) {
        
        # First, find or create the child plate
        my $child_plate = $c->model('HTGTDB::Plate')->find(
          { name => $map->{child_plate}, type => $c->req->params->{csv_type} },
          { key => 'name_type' }
        );

        unless ( defined $child_plate && $child_plate->name ) {
          $child_plate = $c->model('HTGTDB::Plate')->create(
            {
              name            => $map->{child_plate},
              type            => $c->req->params->{csv_type},
              created_user    => $c->user->id,
              created_date    => $date,
              edited_user     => $c->user->id,
              edited_date     => $date
            }
          );
        }
        
        if ( defined $map->{parent_well} && $map->{parent_well} ne "-" && $map->{parent_well} ne "" ) {
          
          # If we have a parent well defined try to link it to the new well
          
          # First look-up the parent plate/well
          my $parent_well = $c->model('HTGTDB::Well')->search(
            {
              well_name    => $map->{parent_well},
              'plate.name' => $map->{parent_plate}
            },
            { join => ['plate'], prefetch => ['plate'] }
          )->first();

          if ( defined $parent_well && $parent_well->well_id ) {

            # Link to the parent...
            $c->model('HTGTDB::PlatePlate')->find_or_create(
              {
                parent_plate_id => $parent_well->plate->plate_id,
                child_plate_id  => $child_plate->plate_id
              }
            );

            # And now the child well
            my $child_well = $c->model('HTGTDB::Well')->create(
              {
                plate_id            => $child_plate->plate_id,
                well_name           => $map->{child_well},
                parent_well_id      => $parent_well->well_id,
                design_instance_id  => $parent_well->design_instance_id,
                edit_user           => $c->user->id,
                edit_date           => $date
              },
              { key => 'plate_id_well_name' }
            );

            # If we have cassette and backbone info to inherit - inherit them!
            $child_well->inherit_from_parent(['cassette', 'backbone'], { edit_user => $c->user->id });

            if ( $child_plate->type =~ /PCS|PGD|PGS|GRQ/ ) {
              $child_well->inherit_from_parent(['clone_name'], { edit_user => $c->user->id });
            }

            # Finally stash the info on the plate we've made
            $plates_made{ $child_plate->name } = $child_plate->plate_id;

          }
          else {
            die 
              "Cannot find parents! Plate: " . $map->{parent_plate} . 
              " Well: " . $map->{parent_well} . "...";
          }
          
        } else {
          
          # Else, just create a blank well...
          
          my $child_well = $c->model('HTGTDB::Well')->create(
            {
              plate_id  => $child_plate->plate_id,
              well_name => $map->{child_well},
              edit_user => $c->user->id,
              edit_date => $date
            },
            { key => 'plate_id_well_name' }
          );
          
        }
        
      }
      
    }
  );
  
  # If we got here all went well! Finish off - woop woop!
  my $message = "Your plate was sucessfully created:<br /><ul>\n";
  foreach my $plate_name ( keys %plates_made ) {
    $message .= "<li>" . $plate_name . " - ";
    $message .= '<a href="' . $c->uri_for('/plate/view') . '?plate_id=' . $plates_made{$plate_name} . '" class="plate_link">view plate</a>';
    $message .= "</li>\n";
  }
  $message .= "</ul>";

  $c->flash->{status_msg} = $message;
  $c->response->redirect( $c->uri_for('/plate/create') );
  return 1;
  
  
}

=head2 update_or_create

Method to update or create a plate.

=cut

sub update_or_create : Local {
  my ( $self, $c ) = @_;
  my %rqp2update = (
    'plate_name' => 'name',
    'plate_type' => 'type',
    'plate_desc' => 'description',
    'plate_lock' => 'is_locked'
  );
  my %update = ( q(edited_user) => $c->user->id );
  while ( my ( $k, $nk ) = each %rqp2update ) {
    if ( exists( ${ $c->req->params }{$k} ) ) {
      my $v = $c->req->params->{$k};
      $update{$nk} = $v;
    }
  }
  my $plate = HTGT::Controller::Plate->find( $c, {} );
  if ($plate) {
    if ( $plate->is_locked eq "y" ) {
      my $error_msg = "Plate " . $plate->name . " is locked and may not be updated\n";
      $c->stash->{error_msg} .= "$error_msg";
      $c->log->info($error_msg);
    }
    else {
      $plate->update( \%update );
    }
  }
  else {
    $update{created_user} = $c->user->id;
    $update{type} ||= $c->stash->{platetype};
    $plate = $c->model(q(HTGTDB::Plate))->create( \%update );
    $c->stash->{status_msg} .= "Plate " . $plate->name . " creation. ";
  }
  return HTGT::Controller::Plate->find( $c, undef, $plate );    #use find to set stash

  # need to set redirect to plate view with a flashed status...?
}

=head2 update_or_create_well

Method to update or create a well(s) (needs JSON encoded data in a data field at the moment).

=cut

sub update_or_create_well : Local {
  my ( $self, $c ) = @_;
  $c->model(q(HTGTDB))->schema->txn_do(
    sub {
      my $plate = HTGT::Controller::Plate->find( $c, {} );
      if ( not defined $plate and exists( ${ $c->req->params }{'plate_name'} ) ) {    #able to create a plate
        $plate = $self->update_or_create($c);
      }

      #Add non JSON data update here?
      my %rqp2update = (
        'well_name'          => 'well_name',
        'qctest_result_id'   => 'qctest_result_id',
        'parent_well_id'     => 'parent_well_id',
        'design_instance_id' => 'design_instance_id',
        'plate_id'           => 'plate_id'
      );
      my $nwda = from_json( $c->req->params->{'data'} );                              #new well data array
      $nwda = ref $nwda eq 'ARRAY' ? $nwda : [];
      foreach my $wh (@$nwda) {
        my $w;
        my $wd = $wh->{well_data};
        foreach (qw(design_instance_id)) {                                            # qctest_result_id)){#shift out of well_data as they/it belong in well
          if ( exists( ${$wd}{$_} ) ) {
            $wh->{$_} = $wd->{$_};
            delete( ${$wd}{$_} );
          }
        }
        my %update = ( q(edit_user) => $c->user->id );
        while ( my ( $k, $nk ) = each %rqp2update ) {
          if ( exists( ${$wh}{$k} ) ) {
            my $v = $wh->{$k};
            $update{$nk} = $v;
          }
        }
        my $m = $c->model(q(HTGTDB::Well));
        if ( $wh->{well_id} ) {
          $w = $m->find( { well_id => $wh->{well_id} } );
          $w->update( \%update );
        }
        elsif ( $update{plate_id} and $update{well_name} ) {
          $w = $m->update_or_create( \%update );
        }
        elsif ( $plate and $update{well_name} ) {
          $w = $plate->wells->update_or_create( \%update );
        }
        else { die "Unable to update or create well\n"; }
        if ( $w and scalar( keys %$wd ) ) {
          while ( my ( $k, $v ) = each %$wd ) {
            $w->well_data->update_or_create( { edit_user => $c->user->id, data_type => $k, data_value => $v } );
          }
        }
      }
      $c->stash->{status_msg} .= scalar(@$nwda) . " well update. ";

      # need to set redirect to plate view with a flashed status...?
    }
  );    #end of transaction
        #Now go back to originating page?
  $c->flash->{status_msg} = $c->stash->{status_msg}
   if exists( $c->stash->{status_msg} )
     and length( $c->stash->{status_msg} );
  $c->flash->{error_msg} = $c->stash->{error_msg}
   if exists( $c->stash->{error_msg} )
     and length( $c->stash->{error_msg} );
  $c->res->redirect( $c->req->referer );
}

=head1

  update user_qc_result table

=cut

sub _update_user_qc_result : Local {
   my ( $self, $c ) = @_;
   
   unless ( $c->check_user_roles("edit") ) {
      $c->flash->{error_msg} = "You are not authorized to perform this function!";
      $c->response->redirect( $c->uri_for('') );      
   }
   
   my $well_id = $c->req->params->{id};
   my $user_qc_result = $c->model('HTGTDB::UserQCResult')->find( { well_id => $well_id });
   my $value = $self->trim( $c->req->params->{value} );
               
   if( $c->req->params->{field} eq 'five_lrpcr_column'){       
      if ($user_qc_result){
	  $user_qc_result->update({
	     five_lrpcr => $value
	  });
	  $c->res->body( $c->req->params->{value} );	
      }else{
	  $c->model('HTGTDB::UserQCResult')->create({
	      well_id => $well_id,
	      five_lrpcr => $value
	  });
	  $c->res->body( $c->req->params->{value} );
      }
   }elsif( $c->req->params->{field} eq 'three_lrpcr_column'){	
	if ($user_qc_result){
	    $user_qc_result->update({
	       three_lrpcr => $value
	    });
	    $c->res->body( $c->req->params->{value});
	}else{
	    $c->model('HTGTDB::UserQCResult')->create({
		well_id => $well_id,
		three_lrpcr => $value
	    });
	    $c->res->body( $c->req->params->{value});
	}
   }
}

=head1

  insert well data do_not_ep

=cut

sub _insert_do_not_ep_flag : Local {
  my ( $self, $c ) = @_;
 
  unless ( $c->check_user_roles("edit") ) {
    $c->flash->{error_msg} = "You are not authorized to perform this function! ";
    $c->response->redirect( $c->uri_for('') );
  }
 
  my $well_id = $c->req->params->{id};
  my $value = $self->trim( $c->req->params->{value} );
 
  my $found = 0;  
  my @well_data = $c->model('HTGTDB::Well')->find({ well_id => $well_id})->well_data;
  
  # update well data
  foreach my $wd (@well_data) {
    if ( $wd->data_type eq 'do_not_ep' ){
       if ( $value eq 'DO_NOT_EP') {
	  $wd->update( {
	      data_value => 'yes',
	      edit_user => $c->user->id,
	      edit_date => \"current_timestamp"
	  });
       }else{
	  $wd->delete();
       }
       $found = 1;
    }
  }

  # can't find exsiting well data, so insert a new one
  if ( $found == 0 ){
    if( $value eq 'DO_NOT_EP' ){
      $c->model('HTGTDB::WellData')->create({
	 well_id => $well_id,
	 edit_user => $c->user->id,
	 edit_date => \"current_timestamp",
	 data_type => 'do_not_ep',
	 data_value => 'yes'
      });
    }
  }
    
  $c->res->body( $c->req->params->{value});
}

=head1

Method to update ALL of the cassette well_data entries on a plate with phase matched cassettes

=cut

sub add_phase_matched_cassettes : Local {
    my ( $self, $c ) = @_;
    my $htgtdb_schema = $c->model('HTGTDB')->schema;
    
    unless ( $c->check_user_roles("edit") ) {
        $c->flash->{error_msg} = 'You are not authorised to do this';
        return $self->go_to_plate_view( $c );
    }

    my $plate_id = $c->req->param( 'plate_id' );
    unless ( $plate_id and $plate_id =~ /^\d+$/ ) {
        $c->flash->{error_msg} = 'Missing or invalid plate id';
        return $self->go_to_plate_list( $c );
    }
    
    my $phase_matched_cassette = $c->req->param( 'phase_matched_cassette' );
    unless ( $phase_matched_cassette ) {
        $c->flash->{error_msg} = 'New phase matched cassette not specified';
        return $self->go_to_plate_view( $c );
    }
    
    my $loader = HTGT::Utils::Plate::AddPhaseMatchedCassette->new(
        schema   => $htgtdb_schema,
        cassette => $phase_matched_cassette,
        plate_id => $plate_id,
        user     => $c->user->id,
    );

    $htgtdb_schema->txn_do(
        sub {
            $loader->add_phase_matched_cassette;
            if ( $loader->has_errors ) {
                $htgtdb_schema->txn_rollback;
                $self->_create_error_message( $c, $loader->errors );
            }
            else {
                $self->_create_update_message( $c, $loader->update_log, $phase_matched_cassette );
            }
        }
    );
    $self->go_to_plate_view( $c );
}

=head1 Utility Methods

=cut

=head2 trim

Method for triming the space of form value

=cut

sub trim : Private {
  my ( $self, $string ) = @_;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

=head2 _create_error_message


=cut

sub _create_error_message {
    my ( $self, $c, $errors ) = @_;
    my $error_message;

    foreach my $line ( sort @$errors ) {
        $error_message .= "$line" . '<br>';
    }
    $c->flash->{error_msg} = $error_message;
    $error_message =~ s/<br>//g;
    $c->log->warn($error_message);

}

=head2 _create_update_message


=cut

sub _create_update_message {
    my ( $self, $c, $update_log, $phase_matched_cassette ) = @_;

    foreach my $log ( sort @$update_log ) {
        $c->log->info($log);
    }
    $c->flash->{status_msg} = "Added $phase_matched_cassette phase matched cassette, update completed";
}

sub go_to_plate_view {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for( '/plate/view', { plate_id => $c->req->param( 'plate_id' ) } ) );
}

sub go_to_plate_list {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for( '/plate/list' ) );
}

sub create_PIQ_lab_number {
    my ( $self, $c ) = @_;
    
    my $piq_lab_number_type = $c->req->params->{piq_location}; 
    return unless $piq_lab_number_type or $piq_lab_number_type eq '-';
    my $wd_rs = $c->model('HTGTDB')->schema->resultset('WellData')->search(
        {
            'plate.type'   => 'PIQ',
            'me.data_type' => 'lab_number',
            'me.data_value' => { 'like' => "$piq_lab_number_type" . '%' },
            
        },
        {
            join   => { 'well' => 'plate' },
        }
    );


    if ( $wd_rs->count ) {
        my @lab_numbers = map{ $_->data_value =~ /(\d+)$/; $1 } grep{ $_->data_value } $wd_rs->all;
        my $current_lab_no = max @lab_numbers;
        return $piq_lab_number_type . ++$current_lab_no if $current_lab_no;
    }
    return;
}

=head1 AUTHOR

Darren Oakley <do2@sanger.ac.uk>

David Jackson <david.jackson@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
