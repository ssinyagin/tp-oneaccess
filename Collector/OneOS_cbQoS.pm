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


package Torrus::Collector::OneOS_cbQoS;

use Torrus::Collector::OneOS_cbQoS_Params;

use Torrus::ConfigTree;
use Torrus::Collector::SNMP;
use Torrus::Log;

use strict;
use Net::hostent;
use Socket;
use Net::SNMP qw(:snmp);

# Register the collector type
$Torrus::Collector::collectorTypes{'oneaccess-cbqos'} = 1;


# List of needed parameters and default values

$Torrus::Collector::params{'oneaccess-cbqos'} =
    \%Torrus::Collector::OneOS_cbQoS_Params::requiredLeafParams;

# Copy parameters from SNMP collector
while( my($key, $val) = each %{$Torrus::Collector::params{'snmp'}} )
{
    $Torrus::Collector::params{'oneaccess-cbqos'}{$key} = $val;
}

my %oiddef =
    (
     # IF-MIB
     'ifDescr'          => '1.3.6.1.2.1.2.2.1.2',

      # ONEACCESS-CLASS-BASED-QOS-MIB
     'ServicePolicyTable'         => '1.3.6.1.4.1.13191.10.3.1.3.1',
     'PolicyIndex'                => '1.3.6.1.4.1.13191.10.3.1.3.1.1.1',
     'IfIndex'                    => '1.3.6.1.4.1.13191.10.3.1.3.1.1.2',
     'IfType'                     => '1.3.6.1.4.1.13191.10.3.1.3.1.1.3',
     'PolicyDirection'            => '1.3.6.1.4.1.13191.10.3.1.3.1.1.4',
     'ObjectsTable'               => '1.3.6.1.4.1.13191.10.3.1.3.3',
     'ObjectsIndex'               => '1.3.6.1.4.1.13191.10.3.1.3.3.1.1',
     'ConfigIndex'                => '1.3.6.1.4.1.13191.10.3.1.3.3.1.2',
     'ObjectsType'                => '1.3.6.1.4.1.13191.10.3.1.3.3.1.3',
     'ParentObjectsIndex'         => '1.3.6.1.4.1.13191.10.3.1.3.3.1.4',
     'PolicyMapName'              => '1.3.6.1.4.1.13191.10.3.1.3.4.1.1',
     'CMName'                     => '1.3.6.1.4.1.13191.10.3.1.3.5.1.1',
     'MatchName'                  => '1.3.6.1.4.1.13191.10.3.1.3.7.1.1',
     'QueueingCfgBandwidth'       => '1.3.6.1.4.1.13191.10.3.1.3.16.1.3',
     'PoliceCfgCIR'               => '1.3.6.1.4.1.13191.10.3.1.3.10.1.1',
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

my %cbQosValueTranslation =
    (
     'IfType' => {
         'mainInterface'  => 1,
         'subInterface'   => 2 },

     'PolicyDirection' => {
         'input'          => 1,
         'output'         => 2 },

     'ObjectsType' => {
         'policymap'      => 1,
         'classmap'       => 2,
         'matchStatement' => 3,
         'queueing'       => 4,
         'randomDetect'   => 5,
         'police'         => 7,
         'set'            => 8 },

     'PoliceCfgConformAction'  => $policyActionTranslation,
     'PoliceCfgExceedAction'   => $policyActionTranslation,
     'PoliceCfgViolateAction'  => $policyActionTranslation
     );


sub translateCbQoSValue
{
    my $value = shift;
    my $name = shift;

    if( defined( $cbQosValueTranslation{$name} ) )
    {
        if( not defined( $cbQosValueTranslation{$name}{$value} ) )
        {
            die('Unknown value to translate for ' . $name .
                ': "' . $value . '"');
        }

        $value = $cbQosValueTranslation{$name}{$value};
    }

    return $value;
}


my %servicePolicyTableParams =
    (
     'IfType'                     => 'cbqos-interface-type',
     'PolicyDirection'            => 'cbqos-direction'
     );


# This list defines the order for entries mapping in
# $cref->{'ServicePolicyMapping'}

my @servicePolicyTableEntries =
    ( 'IfType', 'PolicyDirection', 'IfIndex' );


my %objTypeAttributes =
    (
     # 'policymap'
     1 => {
         'name-oid'   => 'PolicyMapName' },

     # 'classmap'
     2 => {
         'name-param' => 'cbqos-class-map-name',
         'name-oid'   => 'CMName' },
     
     # 'matchStatement'
     3 => {
         'name-param' => 'cbqos-match-statement-name',
         'name-oid'   => 'MatchName' },

     # 'queueing'
     4 => {
         'name-param' => 'cbqos-queueing-bandwidth',
         'name-oid'   => 'QueueingCfgBandwidth' },

     # 'randomDetect'     
     5 => {},
      
     # 'police'
     6 => {
         'name-param' => 'cbqos-police-rate',
         'name-oid'   => 'PoliceCfgRate' }
     );


# This is first executed per target

$Torrus::Collector::initTarget{'oneaccess-cbqos'} =
    \&Torrus::Collector::OneOS_cbQoS::initTarget;

# Derive 'snmp-object' from cbQoS maps and pass the control to SNMP collector

sub initTarget
{
    my $collector = shift;
    my $token = shift;

    my $tref = $collector->tokenData( $token );
    my $cref = $collector->collectorData( 'oneaccess-cbqos' );

    $cref->{'QosEnabled'}{$token} = 1;
    
    $collector->registerDeleteCallback
        ( $token, \&Torrus::Collector::OneOS_cbQoS::deleteTarget );
    
    my $ipaddr =
        Torrus::Collector::SNMP::getHostIpAddress( $collector, $token );
    if( not defined( $ipaddr ) )
    {
        $collector->deleteTarget($token);
        return 0;
    }
    $tref->{'ipaddr'} = $ipaddr;

    return Torrus::Collector::OneOS_cbQoS::initTargetAttributes
        ( $collector, $token );
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
        $cref->{'cbQoSNeedsRemapping'}{$token} = 1;
        return 1;
    }

    my $ipaddr = $tref->{'ipaddr'};
    my $port = $collector->param($token, 'snmp-port');

    my $version = $collector->param($token, 'snmp-version');
    my $community;
    if( $version eq '1' or $version eq '2c' )
    {
        $community = $collector->param($token, 'snmp-community');
    }
    else
    {
        # We use community string to identify the agent.
        # For SNMPv3, it's the user name
        $community = $collector->param($token, 'snmp-username');
    }

    my $hosthash = join('|', $ipaddr, $port, $community);
    $tref->{'hosthash'} = $hosthash;
    
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
        $cref->{'cbQoSNeedsRemapping'}{$token} = 1;
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

    # Retrieve and translate cbQosServicePolicyTable

    if( not defined $cref->{'ServicePolicyTable'}{$hosthash} )
    {
        Debug("Retrieving OneAccess cbQoS maps from $ipaddr");

        my $ref = {};
        $cref->{'ServicePolicyTable'}{$hosthash} = $ref;

        my $result =
            $session->get_table( -baseoid =>
                                 $oiddef{'ServicePolicyTable'} );
        if( not defined( $result ) )
        {
            Error("Error retrieving ServicePolicyTable from $ipaddr: " .
                  $session->error());
            
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
        $cref->{'ServicePolicyMapping'}{$hosthash} = $mapRef;

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

    # Retrieve config information from xxxCfgTable

    if( not defined $cref->{'CfgTable'}{$hosthash} )
    {
        my $ref = {};
        $cref->{'CfgTable'}{$hosthash} = $ref;

        foreach my $table ( 'PolicyMapName', 'CMName',
                            'MatchName', 'QueueingCfgBandwidth',
                            'PoliceCfgRate' )
        {
            my $result = $session->get_table( -baseoid => $oiddef{$table} );
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

    # Retrieve and translate cbQosObjectsTable

    if( not defined $cref->{'ObjectsTable'}{$hosthash} )
    {
        my $ref = {};
        $cref->{'ObjectsTable'}{$hosthash} = $ref;

        my $result =
            $session->get_table( -baseoid =>
                                 $oiddef{'ObjectsTable'} );
        if( not defined( $result ) )
        {
            Error("Error retrieving ObjectsTable from $ipaddr: " .
                  $session->error());

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

        my $confIndexOid = $oiddef{'ConfigIndex'};
        my $objTypeOid = $oiddef{'ObjectsType'};

        my %objects;
        my %objPolicyIdx;

        while( my( $oid, $val ) = each %{$result} )
        {
            my $prefixlen = rindex( $oid, '.' );
            my $objIndex = substr( $oid, $prefixlen + 1 );
            my $prefixOid = substr( $oid, 0, $prefixlen );

            $prefixlen = rindex( $prefixOid, '.' );
            my $policyIndex = substr( $prefixOid, $prefixlen + 1 );
            $prefixOid = substr( $prefixOid, 0, $prefixlen );

            my $entryName = $oidrev{$prefixOid};

            $objects{$objIndex}{$entryName} = $val;
            $objPolicyIdx{$objIndex} = $policyIndex;
        }

        while( my( $objIndex, $attr ) = each %objects )
        {
            my $policyIndex = $objPolicyIdx{$objIndex};

            my $objType = $attr->{'ObjectsType'};
            next if not defined( $objTypeAttributes{$objType} );
                                
            # Compose the object ID as "parent:type:name" string
            my $objectID = '';
            
            my $parentIndex = $attr->{'ParentObjectsIndex'};
            if( $parentIndex > 0 )
            {
                my $parentType = $objects{$parentIndex}{'ObjectsType'};

                my $parentCfgIndex =
                    $objects{$parentIndex}{'ConfigIndex'};
                
                my $parentNameOid =
                    $objTypeAttributes{$parentType}{'name-oid'};

                my $parentName = 
                    $cref->{'CfgTable'}{$hosthash}{
                        $parentCfgIndex}{$parentNameOid};
                
                $objectID .= $parentName . ':';
            }

            $objectID .= $objType  . ':';

            my $objCfgIndex = $attr->{'ConfigIndex'};

            my $objNameOid = $objTypeAttributes{$objType}{'name-oid'};

            if( defined($objNameOid) )
            {
                $objectID .= $cref->{'CfgTable'}{$hosthash}{
                    $objCfgIndex}{$objNameOid};
            }
            
            $ref->{$policyIndex}{$objectID} = $objIndex;
        }
    }

    # Finished retrieving tables
    # now find the snmp-object from token parameters

    # Prepare values for ServicePolicyTable match
    
    my %policyParamValues = ( 'IfIndex' => $ifIndex );
    while( my($name, $param) = each %servicePolicyTableParams )
    {
        my $val = $collector->param($token, $param);
        $val = translateCbQoSValue( $val, $name );
        $policyParamValues{$name} = $val;
    }

    # Find the entry in ServicePolicyTable

    my $mapRef = $cref->{'ServicePolicyMapping'}{$hosthash};

    my $mapString = '';
    foreach my $entryName ( @servicePolicyTableEntries )
    {
        $mapString .=
            sprintf( '%d:', $policyParamValues{$entryName} );
    }

    my $thePolicyIndex = $mapRef->{$mapString};
    if( not defined( $thePolicyIndex ) )
    {
        Error('Cannot find ServicePolicyTable mapping for ' .
              $mapString);
        return undef;
    }

    # compose the object ID from token parameters as "parent:type:name" string

    my $theObjectID = $collector->param($token, 'cbqos-parent-name');
    if( length( $theObjectID ) > 0 )
    {
        $theObjectID .= ':';
    }

    my $theObjectType =
        translateCbQoSValue( $collector->param($token, 'cbqos-object-type'),
                             'ObjectsType' );

    $theObjectID .= $theObjectType . ':';

    my $objNameParam = $objTypeAttributes{$theObjectType}{'name-param'};
    if( defined($objNameParam) )
    {
        $theObjectID .= $collector->param( $token, $objNameParam );
    }
    
    my $theObjectIndex = $cref->{'ObjectsTable'}{$hosthash}->{
        $thePolicyIndex}{$theObjectID};

    if( not defined( $theObjectIndex ) )
    {
        Error('Cannot find object index for ' . $thePolicyIndex . ':' .
              $theObjectType . '--' . $theObjectID);
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

$Torrus::Collector::postProcess{'oneaccess-cbqos'} =
    \&Torrus::Collector::OneOS_cbQoS::postProcess;

sub postProcess
{
    my $collector = shift;
    my $cref = shift;

    # We use some SNMP collector internals
    my $scref = $collector->collectorData( 'snmp' );

    # Flush all QoS object mapping
    foreach my $token ( keys %{$scref->{'needsRemapping'}},
                        keys %{$cref->{'cbQoSNeedsRemapping'}} )
    {
        if( $cref->{'QosEnabled'}{$token} )
        {
            my $tref = $collector->tokenData( $token );
            my $hosthash = $tref->{'hosthash'};    
            
            delete $cref->{'ServicePolicyTable'}{$hosthash};
            delete $cref->{'ServicePolicyMapping'}{$hosthash};
            delete $cref->{'ObjectsTable'}{$hosthash};
            delete $cref->{'CfgTable'}{$hosthash};
            
            delete $scref->{'needsRemapping'}{$token};
            delete $cref->{'cbQoSNeedsRemapping'}{$token};
            if( not Torrus::Collector::OneOS_cbQoS::initTargetAttributes
                ( $collector, $token ) )
            {
                $collector->deleteTarget($token);
            }
        }
    }
}


# Callback executed by Collector

sub deleteTarget
{
    my $collector = shift;
    my $token = shift;

    my $cref = $collector->collectorData( 'oneaccess-cbqos' );

    delete $cref->{'QosEnabled'}{$token};

    Torrus::Collector::SNMP::deleteTarget( $collector, $token );
}
    

1;


# Local Variables:
# mode: perl
# indent-tabs-mode: nil
# perl-indent-level: 4
# End:
