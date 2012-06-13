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


package Torrus::Collector::OneAccess_QoS;

use strict;
use warnings;

use Torrus::Collector::OneAccess_QoS_Params;

use Torrus::ConfigTree;
use Torrus::Collector::SNMP;
use Torrus::Log;

use Net::hostent;
use Socket;
use Net::SNMP qw(:snmp);

# Register the collector type
$Torrus::Collector::collectorTypes{'oneaccess-cbqos'} = 1;


# List of needed parameters and default values

$Torrus::Collector::params{'oneaccess-cbqos'} =
    \%Torrus::Collector::OneAccess_QoS_Params::requiredLeafParams;

# Copy parameters from SNMP collector
while( my($key, $val) = each %{$Torrus::Collector::params{'snmp'}} )
{
    $Torrus::Collector::params{'oneaccess-cbqos'}{$key} = $val;
}

my %oiddef =
    (
     # IF-MIB
     'ifDescr'          => '1.3.6.1.2.1.2.2.1.2',

     # OA-QOS-MIB
     'oacQosServicePolicyTable'         => '1.3.6.1.4.1.13191.10.3.1.3.1',
     'oacQosPolicyIndex'                => '1.3.6.1.4.1.13191.10.3.1.3.1.1.1',
     'oacQosIfIndex'                    => '1.3.6.1.4.1.13191.10.3.1.3.1.1.2',
     'oacQosIfType'                     => '1.3.6.1.4.1.13191.10.3.1.3.1.1.3',
     'oacQosPolicyDirection'            => '1.3.6.1.4.1.13191.10.3.1.3.1.1.4',
     'oacQosObjectsTable'               => '1.3.6.1.4.1.13191.10.3.1.3.3',
     'oacQosConfigIndex'                => '1.3.6.1.4.1.13191.10.3.1.3.3.1.2',
     'oacQosObjectsType'                => '1.3.6.1.4.1.13191.10.3.1.3.3.1.3',
     'oacQosParentObjectsIndex'         => '1.3.6.1.4.1.13191.10.3.1.3.3.1.4',
     'oacQosPolicyMapName'              => '1.3.6.1.4.1.13191.10.3.1.3.4.1.1',
     'oacQosCMName'                     => '1.3.6.1.4.1.13191.10.3.1.3.5.1.1',
     'oacQosMatchName'                  => '1.3.6.1.4.1.13191.10.3.1.3.7.1.1',
     'oacQosQueueingCfgBandwidth'       => '1.3.6.1.4.1.13191.10.3.1.3.16.1.3',
     'oacQosPoliceCfgCIR'               => '1.3.6.1.4.1.13191.10.3.1.3.10.1.1',
     );

my %oidrev;

while( my($name, $oid) = each %oiddef )
{
    $oidrev{$oid} = $name;
}

my $policyActionTranslation = {
    'transmit'          => 1,
    'setIpDSCP'         => 2,
    'setIpPrecedence'   => 3,
    'setQosGroup'       => 4,
    'drop'              => 5,
    'setAtmClp'         => 6,
    'setDiscardClass'   => 7
    };

my %oacQosValueTranslation =
    (
     'oacQosIfType' => {
         'mainInterface'  => 1,
         'subInterface'   => 2 },

     'oacQosPolicyDirection' => {
         'input'          => 1,
         'output'         => 2 },

     'oacQosObjectsType' => {
         'policymap'      => 1,
         'classmap'       => 2,
         'matchStatement' => 3,
         'queueing'       => 4,
         'randomDetect'   => 5,
         'police'         => 7,
         'set'            => 8 },
     );


sub translateCbQoSValue
{
    my $value = shift;
    my $name = shift;

    if( defined( $oacQosValueTranslation{$name} ) )
    {
        if( not defined( $oacQosValueTranslation{$name}{$value} ) )
        {
            die('Unknown value to translate for ' . $name .
                ': "' . $value . '"');
        }

        $value = $oacQosValueTranslation{$name}{$value};
    }

    return $value;
}


my %servicePolicyTableParams =
    (
     'oacQosIfType'                     => 'cbqos-interface-type',
     'oacQosPolicyDirection'            => 'cbqos-direction'
     );


# This list defines the order for entries mapping in
# $ServicePolicyMapping

my @servicePolicyTableEntries =
    ( 'oacQosIfType', 'oacQosPolicyDirection', 'oacQosIfIndex' );


my %objTypeAttributes =
    (
     # 'policymap'
     1 => {
         'name-oid'   => 'oacQosPolicyMapName' },

     # 'classmap'
     2 => {
         'name-param' => 'cbqos-class-map-name',
         'name-oid'   => 'oacQosCMName' },
     
     # 'matchStatement'
     3 => {
         'name-param' => 'cbqos-match-statement-name',
         'name-oid'   => 'oacQosMatchName' },

     # 'queueing'
     4 => {
         'name-param' => 'cbqos-queueing-bandwidth',
         'name-oid'   => 'oacQosQueueingCfgBandwidth' },

     # 'randomDetect'     
     5 => {},
      
     # 'police'
     6 => {
         'name-param' => 'cbqos-police-rate',
         'name-oid'   => 'oacQosPoliceCfgCIR' }
     );


my %ServicePolicyTable;
my %ServicePolicyMapping;
my %ObjectsTable;
my %CfgTable;

# This is first executed per target


$Torrus::Collector::initTarget{'oneaccess-cbqos'} = \&initTarget;

# Derive 'snmp-object' from cbQoS maps and pass the control to SNMP collector

sub initTarget
{
    my $collector = shift;
    my $token = shift;

    my $tref = $collector->tokenData( $token );
    my $cref = $collector->collectorData( 'oneaccess-cbqos' );

    $cref->{'QosEnabled'}{$token} = 1;
    
    $collector->registerDeleteCallback( $token, \&deleteTarget );
    
    my $hosthash = 
        Torrus::Collector::SNMP::getHostHash( $collector, $token );
    if( not defined( $hosthash ) )
    {
        $collector->deleteTarget($token);
        return 0;
    }
    $tref->{'hosthash'} = $hosthash;

    return initTargetAttributes( $collector, $token );
}


# Recursively create the object name

sub make_full_name
{
    my $objhash = shift;
    my $hosthash = shift;
    my $attr = shift;
    my $cref = shift;
    

    # Compose the object ID as "parent:type:name" string
    my $objectID = '';
    
    my $parentIndex = $attr->{'oacQosParentObjectsIndex'};
    if( $parentIndex > 0 )
    {
	$objectID =
            make_full_name($objhash, $hosthash,
                           $objhash->{$parentIndex}, $cref);
    }

    if( $objectID ) {
        $objectID .= ':';
    }

    my $objType = $attr->{'oacQosObjectsType'};

    my $objCfgIndex = $attr->{'oacQosConfigIndex'};
    
    my $objNameOid = $objTypeAttributes{$objType}{'name-oid'};

    if( defined($objNameOid) )
    {
        $objectID .= $CfgTable{$hosthash}{
            $objCfgIndex}{$objNameOid};
    }
    
    $objectID .= ':' . $objType;

    return $objectID;
}


sub initTargetAttributes
{
    my $collector = shift;
    my $token = shift;

    my $tref = $collector->tokenData( $token );
    my $cref = $collector->collectorData( 'oneaccess-cbqos' );

    if( Torrus::Collector::SNMP::activeMappingSessions() > 0 )
    {
        # ifDescr mapping tables are not yet ready
        $cref->{'oacQoSNeedsRemapping'}{$token} = 1;
        return 1;
    }

    my $hosthash = $tref->{'hosthash'};
    
    if( Torrus::Collector::SNMP::isHostDead( $collector, $hosthash ) )
    {
        return 0;
    }

    if( not Torrus::Collector::SNMP::checkUnreachableRetry
        ( $collector, $hosthash ) )
    {
        return 1;
    }

    my $ifDescr = $collector->param($token, 'cbqos-interface-name');
    my $ifIndex =
        Torrus::Collector::SNMP::lookupMap( $collector, $token,
                                            $hosthash,
                                            $oiddef{'ifDescr'}, $ifDescr );

    if( not defined( $ifIndex ) )
    {
        Debug('ifDescr mapping tables are not yet ready for ' . $hosthash);
        $cref->{'oacQoSNeedsRemapping'}{$token} = 1;
        return 1;
    }
    elsif( $ifIndex eq 'notfound' )
    {
        Error("Cannot find ifDescr mapping for $ifDescr at $hosthash");
        return undef;
    }
    
    my $session = Torrus::Collector::SNMP::openBlockingSession
        ( $collector, $token, $hosthash );
    if( not defined($session) )
    {
        return 0;
    }

    my $maxrepetitions = $collector->param($token, 'snmp-maxrepetitions');

    # Retrieve and translate oacQosServicePolicyTable

    if( not defined $ServicePolicyTable{$hosthash} )
    {
        Debug('Retrieving Oneaccess QoS maps from ' . $hosthash);

        my $ref = {};
        $ServicePolicyTable{$hosthash} = $ref;

        my $result =
            $session->get_table
            ( -baseoid => $oiddef{'oacQosServicePolicyTable'},
              -maxrepetitions => $maxrepetitions );
        if( not defined( $result ) )
        {
            Error('Error retrieving oacQosServicePolicyTable from ' .
                  $hosthash . ': ' . $session->error());
            
            # When the remote agent is reacheable, but system objecs are
            # not implemented, we get a positive error_status
            if( $session->error_status() == 0 )
            {
                return Torrus::Collector::SNMP::probablyDead
                    ( $collector, $hosthash );
            }
            else
            {
                return 0;
            }
        }

        while( my( $oid, $val ) = each %{$result} )
        {
            my $prefixlen = rindex( $oid, '.' );
            my $prefixOid = substr( $oid, 0, $prefixlen );
            my $policyIndex = substr( $oid, $prefixlen + 1 );

            my $entryName = $oidrev{$prefixOid};
            if( not defined $entryName )
            {
                Warn("Unknown OID: $prefixOid");
            }
            else
            {
                $ref->{$policyIndex}{$entryName} = $val;
            }
        }

        my $mapRef = {};
        $ServicePolicyMapping{$hosthash} = $mapRef;

        foreach my $policyIndex ( keys %{$ref} )
        {
            my $mapString = '';
            foreach my $entryName ( @servicePolicyTableEntries )
            {
                $mapString .=
                    sprintf( '%d:', $ref->{$policyIndex}{$entryName} );
            }
            $mapRef->{$mapString} = $policyIndex;
        }
    }

    # Retrieve config information from oacQosxxxCfgTable

    if( not defined $CfgTable{$hosthash} )
    {
        my $ref = {};
        $CfgTable{$hosthash} = $ref;

        foreach my $table ( 'oacQosPolicyMapName', 'oacQosCMName',
                            'oacQosMatchStmtName', 'oacQosQueueingCfgBandwidth',
                            'oacQosTSCfgRate', 'oacQosPoliceCfgRate' )
        {
            my $result =
                $session->get_table( -baseoid => $oiddef{$table},
                                     -maxrepetitions => $maxrepetitions );
            if( defined( $result ) )
            {
                while( my( $oid, $val ) = each %{$result} )
                {
                    # Chop heading and trailing space
                    $val =~ s/^\s+//;
                    $val =~ s/\s+$//;

                    my $prefixlen = rindex( $oid, '.' );
                    my $prefixOid = substr( $oid, 0, $prefixlen );
                    my $cfgIndex = substr( $oid, $prefixlen + 1 );

                    my $entryName = $oidrev{$prefixOid};
                    if( not defined $entryName )
                    {
                        Warn("Unknown OID: $prefixOid");
                    }
                    else
                    {
                        $ref->{$cfgIndex}{$entryName} = $val;
                    }
                }
            }
        }
    }

    # Retrieve and translate oacQosObjectsTable

    if( not defined $ObjectsTable{$hosthash} )
    {
        my $ref = {};
        $ObjectsTable{$hosthash} = $ref;

        my $result =
            $session->get_table( -baseoid => $oiddef{'oacQosObjectsTable'},
                                 -maxrepetitions => $maxrepetitions );
        if( not defined( $result ) )
        {
            Error('Error retrieving oacQosObjectsTable from ' . $hosthash .
                  ': ' . $session->error());

            # When the remote agent is reacheable, but system objecs are
            # not implemented, we get a positive error_status
            if( $session->error_status() == 0 )
            {
                return Torrus::Collector::SNMP::probablyDead
                    ( $collector, $hosthash );
            }
            else
            {
                return 0;
            }
        }

        my $confIndexOid = $oiddef{'oacQosConfigIndex'};
        my $objTypeOid = $oiddef{'oacQosObjectsType'};

        my %objects;

        while( my( $oid, $val ) = each %{$result} )
        {
            my $prefixlen = rindex( $oid, '.' );
            my $objIndex = substr( $oid, $prefixlen + 1 );
            my $prefixOid = substr( $oid, 0, $prefixlen );

            $prefixlen = rindex( $prefixOid, '.' );
            my $policyIndex = substr( $prefixOid, $prefixlen + 1 );
            $prefixOid = substr( $prefixOid, 0, $prefixlen );

            my $entryName = $oidrev{$prefixOid};

            $objects{$policyIndex}{$objIndex}{$entryName} = $val;
        }

        while( my( $policyIndex, $objhash ) = each %objects )
        {
            while( my( $objIndex, $attr ) = each %{$objhash} )
            {
                my $objType = $attr->{'oacQosObjectsType'};
                next if not defined( $objTypeAttributes{$objType} );

                my $objectID =
                    make_full_name( $objhash, $hosthash, $attr, $cref );

                $ref->{$policyIndex}{$objectID} = $objIndex;
            }
        }
    }

    # Finished retrieving tables
    # now find the snmp-object from token parameters

    # Prepare values for oacQosServicePolicyTable match
    
    my %policyParamValues = ( 'oacQosIfIndex' => $ifIndex );
    while( my($name, $param) = each %servicePolicyTableParams )
    {
        my $val = $collector->param($token, $param);
        $val = translateCbQoSValue( $val, $name );
        $policyParamValues{$name} = $val;
    }

    # Find the entry in oacQosServicePolicyTable

    my $mapRef = $ServicePolicyMapping{$hosthash};

    my $mapString = '';
    foreach my $entryName ( @servicePolicyTableEntries )
    {
        $mapString .=
            sprintf( '%d:', $policyParamValues{$entryName} );
    }

    my $thePolicyIndex = $mapRef->{$mapString};
    if( not defined( $thePolicyIndex ) )
    {
        Error('Cannot find oacQosServicePolicyTable mapping for ' .
              $mapString);
        return undef;
    }

    # compose the object ID from token parameters as "parent:type:name" string

    my $theObjectID = $collector->param($token, 'cbqos-full-name');
    
    my $theObjectIndex = $ObjectsTable{$hosthash}->{
        $thePolicyIndex}{$theObjectID};

    if( not defined( $theObjectIndex ) )
    {
        Error('Cannot find object index for ' . $thePolicyIndex . ':' .
              '--' . $theObjectID);
        return undef;
    }

    # Finally we got the object to monitor!

    # Prepare the object for snmp collector
    my $theOid = $collector->param( $token, 'snmp-object' );
    $theOid =~ s/POL/$thePolicyIndex/;
    $theOid =~ s/OBJ/$theObjectIndex/;
    $collector->setParam( $token, 'snmp-object', $theOid );

    return Torrus::Collector::SNMP::initTargetAttributes( $collector, $token );
}


# Main collector cycle is actually the SNMP collector

$Torrus::Collector::runCollector{'oneaccess-cbqos'} =
    \&Torrus::Collector::SNMP::runCollector;


# Execute this after the collector has finished

$Torrus::Collector::postProcess{'oneaccess-cbqos'} = \&postProcess;

sub postProcess
{
    my $collector = shift;
    my $cref = shift;

    # We use some SNMP collector internals
    my $scref = $collector->collectorData( 'snmp' );

    my %remapping_hosts;
    
    # Flush all QoS object mapping
    foreach my $token ( keys %{$scref->{'needsRemapping'}},
                        keys %{$cref->{'cbQoSNeedsRemapping'}} )
    {
        if( $cref->{'QosEnabled'}{$token} )
        {
            my $tref = $collector->tokenData( $token );
            my $hosthash = $tref->{'hosthash'};    

            if( not defined($remapping_hosts{$hosthash}) )
            {
                $remapping_hosts{$hosthash} = [];
            }
            push(@{$remapping_hosts{$hosthash}}, $token);
        }
    }

    while(my ($hosthash, $tokens) = each %remapping_hosts )
    {
        delete $ServicePolicyTable{$hosthash};
        delete $ServicePolicyMapping{$hosthash};
        delete $ObjectsTable{$hosthash};
        delete $CfgTable{$hosthash};

        foreach my $token (@{$tokens})
        {
            delete $scref->{'needsRemapping'}{$token};
            delete $cref->{'cbQoSNeedsRemapping'}{$token};
            if( not initTargetAttributes( $collector, $token ) )
            {
                $collector->deleteTarget($token);
            }
        }
    }

    return;
}


# Callback executed by Collector

sub deleteTarget
{
    my $collector = shift;
    my $token = shift;

    my $cref = $collector->collectorData( 'oneaccess-cbqos' );

    delete $cref->{'QosEnabled'}{$token};

    Torrus::Collector::SNMP::deleteTarget( $collector, $token );

    return;
}

    

1;


# Local Variables:
# mode: perl
# indent-tabs-mode: nil
# perl-indent-level: 4
# End:
