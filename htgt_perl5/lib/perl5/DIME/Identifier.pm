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

package DIME::Identifier;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


sub new
{
	my $class = shift;
	my $this = {			
		};
	if( $^O eq 'MSWin32')
	{
		require UUID;
		my $uuid;
		my $string;
		UUID::generate($uuid); 
		UUID::unparse($uuid, $string); 
		return 'uuid:'.$string;
	}
	else
	{
		require Data::UUID;
		my $du = new Data::UUID;
		return 'uuid:'.$du->create_str();
	}
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

DIME::Identifier - Class that generate identifiers for DIME payloads

=head1 SYNOPSIS

  use DIME::Identifier;
  my $id = new DIME::Identifier;

=head1 DESCRIPTION

This class isolates the identifier generation for payloads from DIME::Payload module.

In Win32 platforms UUID module is used and in UNIX, the Data::UUID module.

=head1 SEE ALSO

DIME::Tools

=head1 AUTHOR

Domingo Alcazar Larrea, E<lt>dalcazar@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE


Copyright (C) 2004 Domingo Alcázar Larrea

This program is free software; you can redistribute it and/or
modify it under the terms of the version 2 of the GNU General
Public License as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307

=cut
