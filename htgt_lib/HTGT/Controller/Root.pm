package HTGT::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Net::Domain q(hostfqdn);
use Socket;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

HTGT::Controller::Root - Root Controller for HTGT

=head1 METHODS

=cut

=head2 index

Redirect to our welcome home page

=cut

sub index : Private {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for('/welcome') );
}

=head2 welcome

A redirect for the default home (index) page...

=cut

sub welcome : Global {
    my ( $self, $c ) = @_;

    if ( $c->req->base =~ /eucomm/ || $c->req->params->{style} eq 'EUCOMM' ) {
        $c->forward('/report/eucomm_main');
    }
    else {
        HTGT::Controller::Report::summary_by_gene( $self, $c, $c->stash->{called_elsewhere} = 'true' );
        $c->stash->{do_not_show_login} = 'true';
        $c->stash->{template}          = 'welcome.tt';
    }
}

=head2 enable_js

A redirect to a root warning page for users who don't have javascript enabled

=cut

sub enable_js : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'enable_js.tt';
}

=head2 cassettes

A root page for describing the cassettes we use

=cut

sub cassettes : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'cassettes.tt';
}

=head2 backbones

A root page for describing the backbones we use

=cut

sub backbones : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'backbones.tt';
}

=head2 downloads

A root page for the file downloads

=cut

sub downloads : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'downloads.tt';
}

=head2 biomart

Forwards to /biomart/martview

=cut

#sub biomart : Local {
#    my ( $self, $c ) = @_;
#    $c->response->redirect('http://www.sanger.ac.uk/htgt/biomart/martview');
#}

=head2 access denied

Access denied page to show unauthorised users trying to view non publicly reported data

=cut

sub access_denied : Local {
    my ( $self, $c ) = @_;
    
    $c->stash->{template} = 'access_denied.tt';
}

=head2 default

Handles 404s so they don't get the Catalyst debug page for a 404

=cut

sub default : Private {
    my ( $self, $c ) = @_;

    # Give a 404 response if a page is not found
    $c->stash->{template} = '404.tt';
    $c->response->status(404);
    $c->forward('HTGT::View::TT');
}

=head2 auto

Set up authentication and "style". Run at the beginning of every action's chain.

=cut

sub auto : Private {    #should this go in auto?
    my ( $self, $c ) = @_;

    if ( my $remote_ip = $c->request->header( 'X-Forwarded-For' ) ) {
        $remote_ip =~ s/^.*,\s*//;
        $c->log->debug( "Considering request from remote_ip $remote_ip" );
        my $hostname = gethostbyaddr( inet_aton( $remote_ip ), AF_INET ) || $remote_ip;
        $c->log->debug( "Considering request from hostname $hostname" );            
        if ( grep $hostname =~ /\Q$_\E$/, @{ $c->config->{banned_hosts} } ) {
            $c->log->error( "Denying request from $hostname" );
            $c->response->content_type( 'text/plain' );
            $c->response->body( "access denied\n" );
            $c->response->status( 403 );
            return;
        }
    }

    unless ( $c->user_exists ) {
        $c->authenticate( {}, "ssso" ) || $c->authenticate( {}, "ssso_fallback" );
    }
    
    $c->log->debug( "Username: " . ( $c->user ? $c->user->id : '<undef>' ) );
    
    $c->stash->{server_username} = (getpwuid($<))[0];
    $c->stash->{server_fqdn}     = hostfqdn();
    # Sniff the URL to see if we're getting requests for EUCOMM
    if ( !defined $c->req->base ) { $c->req->base = 'sanger'; }
    if ( !defined $c->req->params->{style} ) { $c->req->params->{style} = 'sanger'; }
   
    return 1;    #necessary in auto to allow continuation to proper actions
}

sub process_sangerweb_addins : Private {
    my ( $self, $c ) = @_;
    
    eval {
        local (*ENV) = $c->engine->env || \%ENV;
        # SangerWeb ignores SERVER_PORT
        if ( $ENV{HTGT_ENV} and $ENV{HTGT_ENV} ne 'Live' and $ENV{SERVER_PORT} and $ENV{SERVER_NAME} !~ /:/ ) {
            $ENV{SERVER_NAME} = $ENV{SERVER_NAME} . ':' . $ENV{SERVER_PORT};
        }
        # SangerWeb hangs when it sees a POST request
        $ENV{REQUEST_METHOD} = 'GET';

        require SangerWeb;
        if ( $c->req->base =~ /eucomm/ || $c->req->params->{style} eq 'EUCOMM' ) {
            $c->stash->{style}       = 'EUCOMM';
            $c->req->params->{style} = 'EUCOMM';
            $ENV{'SERVER_NAME'}      = 'www.eucomm.org';
        }

        my $sanger = SangerWeb->new(
            {
                'author' => 'Sanger Institute Team 87',
                'title'  => 'Sanger Institute High Throughput Gene Targetting',
                'banner' => '',
            }
        );

        $c->stash->{sanger} = $sanger;

        #prepare sanger header having figured out roles....
        if ( $c->req->params->{style} eq 'EUCOMM' ) {
            @{$c->stash}{qw(sanger_header sanger_footer)} = prepare_eucomm_header_footer( $self, $c, $sanger );
        } else {
            @{$c->stash}{qw(sanger_header sanger_footer)} = prepare_sanger_header_footer( $self, $c, $sanger );
        }
    };
    if ( $@ ) {
        $c->log->error( $@ );
    }
}    

=head2 end

Attempt to render a view, if needed.

=cut 

sub end : Private {
    my ( $self, $c ) = @_;

    if ( $c->req->uri =~ /robots\.txt/ ) {
        $c->stash->{template} = 'robots.tt';
        $c->forward('HTGT::View::NakedTT');
        return 1;
    }

    # Optimization: the SangerWeb header/footer and message to users
    # are not needed for AJAX requests.
    unless ( $c->req->header('X-Requested-With') and $c->req->header('X-Requested-With') eq 'XMLHttpRequest' ) {       
        $self->process_sangerweb_addins( $c );
        
        # Check if there are any status messages to show to the users,
        # (from the 'HTGT_STATUS_MSGS' table), If there are any messages,
        # store them in the stash so that they are displayed.
        messageToUsers( $self, $c );
    }
    
    # Catch server errors and give a more useful message
    if ( scalar @{ $c->error } ) {
        $c->stash->{errors}   = $c->error;
        $c->stash->{template} = '500.tt';
        $c->error(0);
        $c->response->content_type('text/html; charset=utf-8');
        $c->response->status(500);
        $c->forward('HTGT::View::TT');
    }
    
    return 1 if $c->response->status =~ /^3\d\d$/;
    return 1 if $c->response->body;
    unless ( $c->response->content_type ) {
        $c->response->content_type('text/html; charset=utf-8');
    }

    # Determine which view we're using
    if ( !defined $c->req->params->{view} ) { 
      if ( defined $c->req->header('X-Requested-With') ) {
          if ( $c->req->header('X-Requested-With') eq 'XMLHttpRequest' ) { $c->req->params->{view} = 'naked'; } 
          else                                                           { $c->req->params->{view} = 'tt'; }
      } else { $c->req->params->{view} = 'tt'; }
    }
    if ( $c->req->params->{view} eq 'naked' ) {
        $c->res->header( 'Pragma' => 'no-cache' );
        $c->forward('HTGT::View::NakedTT');
    }
    elsif ( $c->req->params->{view} eq 'csv' ) {
        $c->res->content_type('text/comma-separated-values');
        $c->forward('HTGT::View::CsvTT');
    }
    elsif ( $c->req->params->{view} eq 'csvdl' ) {
        my $filename = $c->req->params->{file} || $c->stash->{csv_filename} || 'htgt_download.csv';
        $c->res->content_type('text/comma-separated-values');
        $c->res->header( 'Content-Disposition', qq[attachment; filename="$filename"] );
        $c->forward('HTGT::View::CsvTT');
    }
    elsif ( $c->req->params->{view} eq 'tab' ) {
        $c->res->content_type('text/tab-separated-values');
        $c->forward('HTGT::View::TabTT');
    }
    elsif ( $c->req->params->{view} eq 'tabdl' ) {
        my $filename = 'htgt_download.txt';
        if ( $c->req->params->{file} ) { $filename = $c->req->params->{file}; }
        $c->res->content_type('text/tab-separated-values');
        $c->res->header( 'Content-Disposition', qq[attachment; filename="$filename"] );
        $c->forward('HTGT::View::TabTT');
    }
    else {
        $c->forward('HTGT::View::TT');
    }
}

=head2 prepare_sanger_header_footer

Private method to build the Sanger website header and nav menu

=cut

sub prepare_sanger_header_footer : Private {
    my ( $self, $c, $sanger ) = @_;

    ## Call the automated header creation
    my $header = $sanger->header(
        {
            'nph'         => 1,
            'title'       => 'High Throughput Gene Targeting Group Informatics',
            'description' => 'Team87 - High Throughput Gene Targeting Group part of the EUCOMM and KOMP projects.',
            'keywords'    => 'EUCOMM, eucomm, KOMP, komp, gene targeting, informatics, sanger institute, sanger',
            'author'      => 'Team87 Informatics',
            'navhead'     => 'teams.jpg',
            'swoosh'      => 'swoosh_mice.png',
            #'swoosh'      => 'swoosh_cairns.png',
            'heading'     => '<a href="http://www.sanger.ac.uk/Teams/Team87">Team 87</a>',
            #'stylesheet'  => $c->uri_for('/static/css/htgt.css'),
            'navigator2'  => "INSERT NAV HERE", # This is handled in the '/lib/site/sanger_sidebar.tt' template
            'navigator'   => "Project Overview;http://www.sanger.ac.uk/Teams/Team87/,"
              . "Team;http://www.sanger.ac.uk/Teams/Team87/team.shtml,"
              . "Ex Team;http://www.sanger.ac.uk/Teams/Team87/ex.shtml,"
              . "EUCOMM product enquiries;mailto:info.eucomm\@helmholtz-muenchen.de,"
              . "KOMP product enquiries;mailto:orders\@komp.org,"
              . "Website problems;mailto:htgt\@sanger.ac.uk"
        }
    );

    # Replace prototype and scriptaculous...
    my $prototype_uri     = $c->uri_for('/static/javascript/prototype.js');
    my $scriptaculous_uri = $c->uri_for('/static/javascript/scriptaculous.js');
    $header =~ s/http:\/\/(js|jsdev)\.sanger\.ac\.uk\/prototype(\.js|)/$prototype_uri/;
    $header =~ s/http:\/\/(js|jsdev)\.sanger\.ac\.uk\/scriptaculous\/scriptaculous\.js/$scriptaculous_uri/;

    ## Inject our Javascript/CSS needs at the end
    my $our_scripts =
        '<style type="text/css" media="screen, projector">
            /*<![CDATA[*/
                @import "'.$c->uri_for('/static/css/common.css').'";
                @import "'.$c->uri_for('/static/css/htgt.css').'";
            /*]]>*/
        </style>
        
        <script type="text/javascript" src="'.$c->uri_for('/static/javascript/fastinit.js').'"></script>
        <script type="text/javascript" src="'.$c->uri_for('/static/javascript/tablecolumnhide.js').'"></script>
        <script type="text/javascript" src="'.$c->uri_for('/static/javascript/tablekit.js').'"></script>
        <script type="text/javascript" src="'.$c->uri_for('/static/javascript/platetable.js').'"></script>
        <script type="text/javascript" src="'.$c->uri_for('/static/javascript/htgt.js').'"></script>
        <script type="text/javascript" src="'.$c->uri_for('/static/javascript/validation.js').'"></script>
        <script type="text/javascript" src="http://js.sanger.ac.uk/sorttable_v2.js" ></script>
        </head>';
    $header =~ s/<\/head>/$our_scripts/;

    ## Replace Sanger logout URL with application-specific logout
    my $logout_uri = $c->uri_for( '/logout' );
    $header =~ s{\Q<a href="/logout" >\E}{<a href="$logout_uri" >};
        
    return ($header, $sanger->footer);
}

=head2 prepare_eucomm_header_footer

Private method to build the Eucomm website header and nav menu

=cut

sub prepare_eucomm_header_footer : Private {
    my ( $self, $c, $sanger ) = @_;

    local $ENV{'DOCUMENT_ROOT'}='/nfs/WWWdev/EUCOMM_docs/htdocs/';
    my $header = $sanger->header(
        {
            'nph'   => 1,
        }
    );

    return ($header, $sanger->footer);
}

=head2 redirectToSanger

Redirect to main Sanger site so that images in SangerWeb headers 
work for development off www.sanger and wwwdev.sanger

=cut

sub redirectToSanger : Path('/icons') Path('/gfx') {
    my ( $self, $c ) = @_;
    $c->response->redirect( "http://www.sanger.ac.uk/" . $c->req->path );
}

=head2 redirectToSelf

Redirect to requests containing "/catalyst/HTGT/static" - required for some static content on live sites - to appropriate action. Allows our development boxes to work....

=cut

sub redirectToSelf : Path('/catalyst/HTGT/static') Path('/htgt/static') {
    my ( $self, $c ) = @_;
    my $uri = $c->req->uri;
    if ( $uri =~ s/(htgt|catalyst\/HTGT)\/(static)/$2/ ) {
        $c->res->redirect($uri);
    }
    else { die "Failed catalyst/HTGT redirect for $uri"; }
}

=head2 messageToUsers

For Vivek - quickly put messages (happy, sad, crazy or otherwise) to the view. 

=cut

sub messageToUsers : Private {
    my ( $self, $c ) = @_;

    use DBI;
    my $dbh = $c->model('HTGTDB')->storage->dbh or die "No DB found!";

    my $sql_query = (
        q/
			SELECT HTGT_STATUS_MSGS.msg, TO_CHAR(HTGT_STATUS_MSGS.the_date, 'DD-MON-YYYY HH:MI')
			FROM HTGT_STATUS_MSGS
			WHERE HTGT_STATUS_MSGS.is_active is not NULL
			/
    );

    if ( $c->req->params->{style} eq 'EUCOMM' ) {
        $sql_query .= 'AND HTGT_STATUS_MSGS.is_eucomm is not NULL';
    }

    my $sql = $dbh->prepare($sql_query);
    $sql->execute;
    $c->stash->{status_msg_array} = $sql->fetchall_arrayref();
    $sql->finish();
}

=head1 AUTHOR

Vivek Iyer

David K Jackson <david.jackson@sanger.ac.uk>

Darren Oakley <do2@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
