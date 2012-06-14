#  Copyright (C) 2009  OneAccess Networks
#  Based on the Cisco plugin developed by Stanislav Sinyagin
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.


package Torrus::Collector::OneAccess_QoS_Params;

use strict;
use warnings;


# List of needed parameters and default values

our %requiredLeafParams =
    (
     'cbqos-direction'              => {
         'input'          => undef,
         'output'         => undef },
     
     'cbqos-interface-name'         => undef,
     
     'cbqos-interface-type'         =>  {
         'mainInterface'  => undef,
         'subInterface'   => undef },
              
     'cbqos-object-type'            => {
         'policymap'      => undef,
         'classmap'       => {
             'cbqos-class-map-name' => undef },
         'matchStatement' => {
             'cbqos-match-statement-name' => undef },
         'queueing'       => {
             'cbqos-queueing-bandwidth' => undef },
         'randomDetect'   => undef,

         'police'         => {
             'cbqos-police-rate' => undef },
         'set'            => undef },
     
     'cbqos-parent-name' => undef,
     'cbqos-full-name' => undef
     );


sub initValidatorLeafParams
{
    my $hashref = shift;
    $hashref->{'ds-type'}{'collector'}{'collector-type'}{'oneaccess-cbqos'} =
        \%requiredLeafParams;
}


1;


# Local Variables:
# mode: perl
# indent-tabs-mode: nil
# perl-indent-level: 4
# End:
