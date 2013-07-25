# Copyright (C) 2004 Domingo Alcázar Larrea
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the version 2 of the GNU General
# Public License as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307

package DIME::Parser;

use 5.008;
use strict;
use warnings;
use IO::Wrap;
use DIME::Message;
use DIME::Record;
use DIME::Payload;
use IO::Scalar;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DIME ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.

my $DIME_VERSION = 1;

sub new
{
	my $class = shift;	
	my $this = {
			
		};
	return bless $this, $class;
}

# Read a DIME message and parse it extracting all
# the Payloads
sub parse
{
	my $self = shift;
	my $in = shift;
	my $buf;
	# Create a new Message
	my $message = new DIME::Message;
	my $read_bytes = 0;
	while(!$in->eof())
	{	
		# Create a new Payload
		my $payload = new DIME::Payload;
		my $end = 0;
		my $start = 1;
		while(!$end)
		{
			# Create a new Record and read from stream...		
			my $record = new DIME::Record;
			$read_bytes += $record->read($in);
			if($start)
			{
				$payload->type($record->type());
				$payload->id($record->id());
				$payload->tnf($record->tnf());
				$start = 0;
			}
			$payload->add_record($record);
			$end =1 if($record->cf()==0);
		}
		# Add payload to the Message
		$message->add_payload($payload);
	}
	return $message;
}

sub parse_data
{
	my $self = shift;
	my $ref_data = shift;
	my $io = new IO::Scalar $ref_data;
	my $message = $self->parse($io);
	$io->close;
	return $message;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

DIME - Perl extension for blah blah blah

=head1 SYNOPSIS

  use DIME;
  blah blah blah

=head1 ABSTRACT

  This should be the abstract for DIME.
  The abstract is used when making PPD (Perl Package Description) files.
  If you don't want an ABSTRACT you should also edit Makefile.PL to
  remove the ABSTRACT_FROM option.

=head1 DESCRIPTION

Stub documentation for DIME, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
