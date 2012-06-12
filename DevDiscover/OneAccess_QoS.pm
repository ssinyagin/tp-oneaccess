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


# OneOS Class-based QoS discovery

package Torrus::DevDiscover::OneAccess_QoS;

use strict;
use warnings;
use Torrus::Log;


$Torrus::DevDiscover::registry{'OneAccess_QoS'} = {
    'sequence'     => 510,
    'checkdevtype' => \&checkdevtype,
    'discover'     => \&discover,
    'buildConfig'  => \&buildConfig
    };


our %oiddef =
    (
     # OA-QOS-MIB
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

     'PolicyMapCfgTable'          => '1.3.6.1.4.1.13191.10.3.1.3.4',
     'PolicyMapName'              => '1.3.6.1.4.1.13191.10.3.1.3.4.1.1',
 
     'CMCfgTable'                 => '1.3.6.1.4.1.13191.10.3.1.3.5',
     'CMName'                     => '1.3.6.1.4.1.13191.10.3.1.3.5.1.1',
     'CMInfo'                     => '1.3.6.1.4.1.13191.10.3.1.3.5.1.2',

     'MatchCfgTable'              => '1.3.6.1.4.1.13191.10.3.1.3.7',
     'MatchName'                  => '1.3.6.1.4.1.13191.10.3.1.3.7.1.1',
     'MatchInfo'                  => '1.3.6.1.4.1.13191.10.3.1.3.7.1.2',

     'QueueingCfgTable'           => '1.3.6.1.4.1.13191.10.3.1.3.16',
     'QueueingCfgFlowEnabled'     => '1.3.6.1.4.1.13191.10.3.1.3.16.1.1',
     'QueueingCfgPriorityEnabled' => '1.3.6.1.4.1.13191.10.3.1.3.16.1.2',
     'QueueingCfgBandwidth'       => '1.3.6.1.4.1.13191.10.3.1.3.16.1.3',
     'QueueingCfgBandwidthUnits'  => '1.3.6.1.4.1.13191.10.3.1.3.16.1.4',
     'QueueingCfgAggregateQSize'  => '1.3.6.1.4.1.13191.10.3.1.3.16.1.5',
     'QueueingCfgDynamicQNumber'  => '1.3.6.1.4.1.13191.10.3.1.3.16.1.6',
     'QueueingCfgPrioBurstSize'   => '1.3.6.1.4.1.13191.10.3.1.3.16.1.7',
     'QueueingCfgQLimitUnits'     => '1.3.6.1.4.1.13191.10.3.1.3.16.1.8',
     'QueueingCfgAggregateQLimit' => '1.3.6.1.4.1.13191.10.3.1.3.16.1.9',
  
     'WREDCfgTable'                => '1.3.6.1.4.1.13191.10.3.1.3.13',
     'WREDCfgExponWeight'          => '1.3.6.1.4.1.13191.10.3.1.3.13.1.1',
     'WREDCfgDscpPrec'             => '1.3.6.1.4.1.13191.10.3.1.3.13.1.2',
     'WREDCfgECNEnabled'           => '1.3.6.1.4.1.13191.10.3.1.3.13.1.3',
 
     'WREDClassCfgTable'           => '1.3.6.1.4.1.13191.10.3.1.3.14',
     'WREDValue'                   => '1.3.6.1.4.1.13191.10.3.1.3.14.1.1',
     'WREDCfgPktDropProb'          => '1.3.6.1.4.1.13191.10.3.1.3.14.1.2',
     'WREDClassCfgThresholdUnit'   => '1.3.6.1.4.1.13191.10.3.1.3.14.1.3',
     'WREDClassCfgMinThreshold'    => '1.3.6.1.4.1.13191.10.3.1.3.14.1.4',
     'WREDClassCfgMaxThreshold'    => '1.3.6.1.4.1.13191.10.3.1.3.14.1.5',

     'PoliceCfgTable'             => '1.3.6.1.4.1.13191.10.3.1.3.10',
     'PoliceCfgCIR'               => '1.3.6.1.4.1.13191.10.3.1.3.10.1.1',
     'PoliceCfgCIR64'             => '1.3.6.1.4.1.13191.10.3.1.3.10.1.2',
     'PoliceCfgBurstSize'         => '1.3.6.1.4.1.13191.10.3.1.3.10.1.3',
     'PoliceCfgPIR'               => '1.3.6.1.4.1.13191.10.3.1.3.10.1.4',
     'PoliceCfgExtBurstSize'      => '1.3.6.1.4.1.13191.10.3.1.3.10.1.5',
     'PoliceCfgConformAction'     => '1.3.6.1.4.1.13191.10.3.1.3.10.1.6',
     'PoliceCfgConformSetValue'   => '1.3.6.1.4.1.13191.10.3.1.3.10.1.7',
     'PoliceCfgExceedAction'      => '1.3.6.1.4.1.13191.10.3.1.3.10.1.8',
     'PoliceCfgExceedSetValue'    => '1.3.6.1.4.1.13191.10.3.1.3.10.1.9',
     'PoliceCfgViolateAction'     => '1.3.6.1.4.1.13191.10.3.1.3.10.1.10',
     'PoliceCfgViolateSetValue'   => '1.3.6.1.4.1.13191.10.3.1.3.10.1.11'
       );

# Object types "policymap", "set" are not used for statistics.

my %supportedObjectTypes =
    (
     'policymap'       => 1,
     'classmap'        => 1,
     'matchStatement'  => 1,
     'queueing'        => 1,
     'randomDetect'    => 1,
     'police'          => 1
     );

my %cfgTablesForType =
    (
     'policymap'       => ['PolicyMapCfgTable'],
     'classmap'        => ['CMCfgTable'],
     'matchStatement'  => ['MatchCfgTable'],
     'queueing'        => ['QueueingCfgTable'],
     'randomDetect'    => ['WREDCfgTable', 'WREDClassCfgTable'],
     'police'          => ['PoliceCfgTable']
     );


sub checkdevtype
{
    my $dd = shift;
    my $devdetails = shift;

    my $session = $dd->session();

    # QoS templates use 64-bit counters, so SNMPv1 is explicitly unsupported
    
    if( $devdetails->isDevType('OneAccess') and
        $devdetails->param('snmp-version') ne '1' and
        $dd->checkSnmpTable('ServicePolicyTable') )
    {
        return 1;
    }

    return 0;
}


sub discover
{
    my $dd = shift;
    my $devdetails = shift;

    my $session = $dd->session();
    my $data = $devdetails->data();

    # Process ServicePolicyTable

    $data->{'cbqos_policies'} = {};

    foreach my $policyIndex
        ( $devdetails->getSnmpIndices( $dd->oiddef('IfType') ) )
    {
        $data->{'cbqos_policies'}{$policyIndex} = {};

        foreach my $row ('IfIndex','IfType', 'PolicyDirection')
        {
            my $value = $devdetails->snmpVar($dd->oiddef($row) .
                                             '.' . $policyIndex);
            if( defined( $value ) )
            {
                $value = translateCbQoSValue( $value, $row );            
                $data->{'cbqos_policies'}{$policyIndex}{$row} = $value;
		
            }
        }
    }

    # Process ObjectsTable
    $data->{'cbqos_objects'} = {};

    my $ObjectsTable =
        $session->get_table( -baseoid => $dd->oiddef('ObjectsTable') );
    if( not defined( $ObjectsTable ) )
    {
	Error('ObjectsTable not defined');
        return 1;
    }
    else
    {
        $devdetails->storeSnmpVars( $ObjectsTable );
    }

    my $needTables = {};

    foreach my $policyIndex ( keys %{$data->{'cbqos_policies'}} )
    {
        foreach my $objectIndex
            ( $devdetails->getSnmpIndices( $dd->oiddef('ConfigIndex') .
                                           '.' . $policyIndex ) )
        {
            my $object = { 'PolicyIndex' => $policyIndex };
	             
            foreach my $row ( 'ConfigIndex',
                              'ObjectsType',
                              'ParentObjectsIndex' )
            {
                my $value = $devdetails->snmpVar($dd->oiddef($row) .
                                                 '.' . $policyIndex .
                                                 '.' . $objectIndex);
                $value = translateCbQoSValue( $value, $row );
                $object->{$row} = $value;
     
            }

            my $objType = $object->{'ObjectsType'};
  
            # Store only objects of supported types
            my $takeit = $supportedObjectTypes{$objType};

	       
            # Suppress unneeded objects
            if( $takeit and
                $devdetails->param('OneOS_cbQoS::classmaps-only') eq 'yes'
                and
                $objType ne 'policymap' and
                $objType ne 'classmap' )
            {
                $takeit = 0;
            }

            if( $takeit and
                $devdetails->param('OneOS_cbQoS::suppress-match-statements')
                eq 'yes' and
                $objType eq 'matchStatement' )
            {
                $takeit = 0;
            }

            if( $takeit )
            {
                $data->{'cbqos_objects'}{$objectIndex} = $object;   
      
                # Store the hierarchy information
                my $parent = $object->{'ParentObjectsIndex'};
                if( not exists( $data->{'cbqos_children'}{$parent} ) )
                {
                    $data->{'cbqos_children'}{$parent} = [];
		 }
                push( @{$data->{'cbqos_children'}{$parent}}, $objectIndex );
		
                foreach my $tableName
                    ( @{$cfgTablesForType{$object->{'ObjectsType'}}} )
                {
                    $needTables->{$tableName} = 1;
                }
            }
        }
    }

    # Retrieve the needed SNMP tables

    foreach my $tableName ( keys %{$needTables} )
    {
        my $table =
            $session->get_table( -baseoid => $dd->oiddef( $tableName ) );
        if( defined( $table ) )
        {
            $devdetails->storeSnmpVars( $table );
        }
        else
        {
            Error('Error retrieving ' . $tableName);
            return 0;
        }
    }

    # Prepare the list of DSCP values for RED
    my @dscpValues;
    if( defined( $devdetails->param('OneOS_cbQoS::red-dscp-values') ) )
    {
        @dscpValues =
            split(',', $devdetails->param('OneOS_cbQoS::red-dscp-values'));
    }
    else
    {
        @dscpValues = @Torrus::DevDiscover::OneOS_cbQoS::RedDscpValues;
    }

    # Process xxxCfgTable
    $data->{'cbqos_objcfg'} = {};
                
    while( my( $objectIndex, $objectRef ) =  each %{$data->{'cbqos_objects'}} )  
    {
        my $objConfIndex = $objectRef->{'ConfigIndex'};
        my $objType = $objectRef->{'ObjectsType'};
        my $object = {};
        my @rows = ();
       
        # sometimes configuration changes leave garbage like objects
        # with empty configuration.        
        my %mandatory; 

        if( $objType eq 'policymap' )
        {
            push( @rows, 'PolicyMapName');
            $mandatory{'PolicyMapName'} = 1;
        }
        elsif( $objType eq 'classmap' )
        {
            push( @rows, 'CMName', 'CMInfo' );
            $mandatory{'CMName'} = 1;
        }
        elsif( $objType eq 'matchStatement' )
        {
            push( @rows, 'MatchName' );
            $mandatory{'MatchName'} = 1;
        }
        elsif( $objType eq 'queueing' )
        {
            push( @rows,
                  'QueueingCfgFlowEnabled',
                  'QueueingCfgPriorityEnabled',
                  'QueueingCfgBandwidth',
                  'QueueingCfgBandwidthUnits',
                  'QueueingCfgAggregateQSize',
                  'QueueingCfgDynamicQNumber',
                  'QueueingCfgPrioBurstSize',
                  'QueueingCfgQLimitUnits',
                  'QueueingCfgAggregateQLimit');
            $mandatory{'QueueingCfgBandwidth'} = 1;
            $mandatory{'QueueingCfgBandwidthUnits'} = 1;
        }
        elsif( $objType eq 'randomDetect')
        {
            push( @rows,
                  'WREDCfgExponWeight',
                  'WREDCfgDscpPrec',
                  'WREDCfgECNEnabled' );
            $mandatory{'WREDCfgExponWeight'} = 1;
        }

        elsif( $objType eq 'police' )
        {
            push( @rows,
                  'PoliceCfgCIR',
                  'PoliceCfgCIR64',
                  'PoliceCfgBurstSize',
                  'PoliceCfgPIR',
                  'PoliceCfgExtBurstSize',
                  'PoliceCfgConformAction',
                  'PoliceCfgConformSetValue',
                  'PoliceCfgExceedAction',
                  'PoliceCfgExceedSetValue',
                  'PoliceCfgViolateAction',
                  'PoliceCfgViolateSetValue');
            $mandatory{'PoliceCfgCIR'} = 1;
        }
        else
        {
            Error('Unsupported object type: ' . $objType);
        }

        foreach my $row ( @rows )
        {
            my $value = $devdetails->snmpVar($dd->oiddef($row) .
                                             '.' . $objConfIndex);
	    

            if( length( $value ) > 0 )
            {
                $value = translateCbQoSValue( $value, $row );
                $data->{'cbqos_objcfg'}{$objConfIndex}{$row} = $value;
            }
            elsif( $mandatory{$row} )
            {
                Warn('Object with missing mandatory configuration: ' .
                     'PolicyIndex=' . $objectRef->{'PolicyIndex'} .
                     ', ObjectsIndex=' . $objectIndex);
                delete $data->{'cbqos_objects'}{$objectIndex};
                $objType = 'DELETED';
            }
        }
   
        # In addition, get per-DSCP RED configuration
        if( $objType eq 'randomDetect')
        {
            foreach my $dscp ( @dscpValues )
            {
                foreach my $row ( qw(WREDCfgPktDropProb
                                     WREDClassCfgThresholdUnit
                                     WREDClassCfgMinThreshold
                                     WREDClassCfgMaxThreshold) )
                {
                    my $dscpN = translateDscpValue( $dscp );
                    my $value = $devdetails->snmpVar($dd->oiddef($row) .
                                                     '.' . $objConfIndex .
                                                     '.' . $dscpN);
                    if( length( $value ) > 0 )
                    {
                        $value = translateCbQoSValue( $value, $row );
                        $data->{'cbqos_redcfg'}{$objConfIndex}{$dscp}{$row} =
                            $value;
                    }
                }
            }
        }
    }

    return 1;
}

sub buildConfig
{
    my $devdetails = shift;
    my $cb = shift;
    my $devNode = shift;

    my $data = $devdetails->data();

    my $topNode =
        $cb->addSubtree( $devNode, 'QoS_Stats', undef,
                         ['OneOS_cbQoS::oneaccess-cbqos-subtree']);
   
    # Recursively build a subtree for every policy

    buildChildrenConfigs( $data, $cb, $topNode, '0', '', '' );
}


sub buildChildrenConfigs
{
    my $data = shift;
    my $cb = shift;
    my $parentNode = shift;
    my $parentObjIndex = shift;
    my $parentObjType = shift;
    my $parentObjName = shift;

    if( not defined( $data->{'cbqos_children'}{$parentObjIndex} ) )
    {
        return;
    }

    my $precedence = 10000;
    
    foreach my $objectIndex ( sort { $a <=> $b }
                              @{$data->{'cbqos_children'}{$parentObjIndex}} )
    {
        my $objectRef     = $data->{'cbqos_objects'}{$objectIndex};
        my $objConfIndex  = $objectRef->{'ConfigIndex'};
        my $objType       = $objectRef->{'ObjectsType'};
        my $configRef     = $data->{'cbqos_objcfg'}{$objConfIndex};

        my $objectName = '';
        my $subtreeName = '';
        my $subtreeComment = '';
        my $objectNick = '';
        my $param = {
            'cbqos-object-type' => $objType,
            'precedence'        => $precedence--
            };        
        my @templates;

        $param->{'cbqos-parent-type'} = $parentObjType;
        $param->{'cbqos-parent-name'} = $parentObjName;
                
        my $buildSubtree = 1;
        
        if( $objType eq 'policymap' )
        {
            $objectName = $configRef->{'PolicyMapName'};

            my $policyRef = $data->{'cbqos_policies'}{$objectIndex};
            if( ref( $policyRef ) )
            {
                my $ifIndex    = $policyRef->{'IfIndex'};
                my $interface  = $data->{'interfaces'}{$ifIndex};

                if( defined( $interface ) )
                {
                    my $interfaceName = $interface->{'ifDescr'};
                    $param->{'cbqos-interface-name'} = $interfaceName;
                    $param->{'searchable'} = 'yes';
                    
                    my $policyNick =
                        $interface->{$data->{'nameref'}{'ifNick'}};

                    $subtreeName =
                        $interface->{$data->{'nameref'}{'ifSubtreeName'}};
                
                    $subtreeComment = $interfaceName;
                    
                    my $ifType = $policyRef->{'IfType'};
                    $param->{'cbqos-interface-type'} = $ifType;

  
                    
                    my $direction = $policyRef->{'PolicyDirection'};
                    
                    # input -> in, output -> out
                    my $dir = $direction;
                    $dir =~ s/put$//;
                    
                    $subtreeName .= '_' . $dir;
                    $subtreeComment .= ' ' . $direction . ' policy';
                    $param->{'cbqos-direction'} = $direction;
                    $policyNick .=  '_' . $dir;
                    
                    $param->{'cbqos-policy-nick'} = $policyNick;

                    my $ifComment =
                        $interface->{$data->{'nameref'}{'ifComment'}};
                    if( length( $ifComment ) > 0 )
                    {
                        $subtreeComment .= ' (' . $ifComment . ')';
                    }
                }
                else
                {
                    $buildSubtree = 0;
                }
            }
            else
            {
                # Nested policy map
                $subtreeName = $objectName;
                $subtreeComment = 'Policy map: ' . $objectName;
            }                

            $param->{'legend'} = 'Policy map:' . $objectName;
     
            push( @templates,
                  'OneOS_cbQoS::oneaccess-cbqos-policymap-subtree' );
        }
        elsif( $objType eq 'classmap' )
        {
            $objectName = $configRef->{'CMName'};
            $subtreeName = $objectName;
            $subtreeComment = 'Class: ' . $objectName;
            $objectNick = 'cm_' . $objectName;
            $param->{'cbqos-class-map-name'} = $objectName;
            push( @templates,
                  'OneOS_cbQoS::oneaccess-cbqos-classmap-meters' );

            $param->{'legend'} =
                sprintf('Match: %s;', $configRef->{'CMInfo'});
    
        }
        elsif( $objType eq 'matchStatement' )
        {
            my $name = $configRef->{'MatchName'};
            $subtreeName = $name;
            $subtreeComment = 'Match statement statistics';
           $objectNick = 'ms_' . $name;
            $param->{'cbqos-match-statement-name'} = $name;
            push( @templates,
                  'OneOS_cbQoS::oneaccess-cbqos-match-stmt-meters' );
        }
        elsif( $objType eq 'queueing' )
        {
            my $bandwidth = $configRef->{'QueueingCfgBandwidth'};
            my $units = $configRef->{'QueueingCfgBandwidthUnits'};

            $subtreeName = 'Bandwidth_' . $bandwidth . '_' . $units;
            $subtreeComment = 'Queueing statistics';
            $objectNick = 'qu_' . $bandwidth;
            $param->{'cbqos-queueing-bandwidth'} = $bandwidth;
            push( @templates,
                  'OneOS_cbQoS::oneaccess-cbqos-queueing-meters' );

            $param->{'legend'} =
                sprintf('Guaranteed Bandwidth: %d %s;' .
                        'Flow: %s;' .
                        'Priority: %s;',                        
                        $bandwidth, $units,                        
                        $configRef->{'QueueingCfgFlowEnabled'},
                        $configRef->{'QueueingCfgPriorityEnabled'});

            if( defined( $configRef->{'QueueingCfgAggregateQLimit'} ) )
            {
                $param->{'legend'} .=
                    sprintf('Max Queue Size: %d %s;',
                            $configRef->{'QueueingCfgAggregateQLimit'},
                            $configRef->{'QueueingCfgQLimitUnits'});
            }
            elsif( defined( $configRef->{'QueueingCfgAggregateQSize'} ) )
            {
                $param->{'legend'} .=
                    sprintf('Max Queue Size: %d packets;',
                            $configRef->{'QueueingCfgAggregateQSize'});
            }
    
            if( $configRef->{'QueueingCfgDynamicQNumber'} > 0 )
            {
                $param->{'legend'} .=
                    sprintf('Max Dynamic Queues: %d;',
                            $configRef->{'QueueingCfgDynamicQNumber'});
            }

            if( $configRef->{'QueueingCfgPrioBurstSize'} > 0 )
            {
                $param->{'legend'} .=
                    sprintf('Priority Burst Size: %d bytes;',
                            $configRef->{'QueueingCfgPrioBurstSize'});
            }
        }
        elsif( $objType eq 'randomDetect')
        {
            $subtreeName = 'WRED';
            $subtreeComment = 'Weighted Random Early Detect Statistics';
            $param->{'legend'} =
                sprintf('Exponential Weight: %d;',
                        $configRef->{'WREDCfgExponWeight'});
            push( @templates,
                  'OneOS_cbQoS::oneaccess-cbqos-red-subtree' );

            if( $configRef->{'WREDCfgDscpPrec'} == 1 )
            {
                Error('Precedence-based WRED is not supported');
            }
        }

        elsif( $objType eq 'police' )
        {
            my $rate = $configRef->{'PoliceCfgCIR'};
            $subtreeName = sprintf('Police_%d_bps', $rate );
            $subtreeComment = 'Rate policing statistics';
            $objectNick = 'p_' . $rate;
            $param->{'cbqos-police-rate'} = $rate;
            push( @templates,
                  'OneOS_cbQoS::oneaccess-cbqos-police-meters' );

            $param->{'legend'} =
                sprintf('Committed Rate: %d bits/second;' .
                        'Burst Size: %d Octets;' .
                        'Ext Burst Size: %d Octets;' .
                        'Conform Action: %s;' .
                        'Conform Set Value: %d;' .
                        'Exceed Action: %s;' .
                        'Exceed Set Value: %d;' .
                        'Violate Action: %s;' .
                        'Violate Set Value: %d',
                        $rate,
                        $configRef->{'PoliceCfgBurstSize'},
                        $configRef->{'PoliceCfgExtBurstSize'},
                        $configRef->{'PoliceCfgConformAction'},
                        $configRef->{'PoliceCfgConformSetValue'},
                        $configRef->{'PoliceCfgExceedAction'},
                        $configRef->{'PoliceCfgExceedSetValue'},
                        $configRef->{'PoliceCfgViolateAction'},
                        $configRef->{'PoliceCfgViolateSetValue'});
        }
        else
        {
            $buildSubtree = 0;
        }

        if( $buildSubtree )
        {
            $subtreeName =~ s/\W+/_/g;
            $subtreeName =~ s/_+$//;
            $objectNick =~ s/\W+/_/g;
            $objectNick =~ s/_+$//;

            if( $objectNick )
            {
                if( length($parentObjName) > 0 )
                {
                    # For previous version compatibility, we have to
                    # preserve dash (-) in parent name
                    my $parent = $parentObjName;                    
                    $parent =~ s/[^0-9a-zA-Z-_]/_/g;
                    $parent =~ s/__/_/g;
                    $objectNick = $parent . '_' . $objectNick;
                }
                
                $param->{'cbqos-object-nick'} = $objectNick;
            }

            $param->{'comment'} = $subtreeComment;

            my $objectNode = $cb->addSubtree( $parentNode, $subtreeName,
                                             $param, \@templates );

            if( $objType eq 'randomDetect')
            {
                my $ref = $data->{'cbqos_redcfg'}{$objConfIndex};
                foreach my $dscp
                    (sort {translateDscpValue($a) <=> translateDscpValue($b)}
                     keys %{$ref})
                {
                    my $cfg = $ref->{$dscp};
                    my $dscpN = translateDscpValue( $dscp );

                    my $param = {
                        'comment' => sprintf('DSCP %d', $dscpN),
                        'cbqos-red-dscp' => $dscpN
                        };

                    if( defined( $cfg->{'WREDClassCfgThresholdUnit'} ) )
                    {
                        $param->{'legend'} =
                            sprintf('Min Threshold: %d %s;' .
                                    'Max Threshold: %d %s;',
                                    $cfg->{'WREDClassCfgMinThreshold'},
                                    $cfg->{'WREDClassCfgThresholdUnit'},
                                    $cfg->{'WREDClassCfgMaxThreshold'},
                                    $cfg->{'WREDClassCfgThresholdUnit'});
                    }
                    else
                    {
                        $param->{'legend'} =
                            sprintf('Min Threshold: %d packets;' .
                                    'Max Threshold: %d packets;',
                                    $cfg->{'WREDCfgMinThreshold'},
                                    $cfg->{'WREDCfgMaxThreshold'});
                    }
                    
                    $cb->addSubtree
                        ( $objectNode, $dscp,
                          $param, ['OneOS_cbQoS::oneaccess-cbqos-red-meters'] );
                }
            }
            else
            {
                # Recursivery build children
                buildChildrenConfigs( $data, $cb, $objectNode, $objectIndex,
                                      $objType, $objectName );
            }
        }
    }
}


my $policyActionTranslation = {
    0 => 'unknown',
    1 => 'transmit',
    2 => 'setIpDSCP',
    3 => 'setIpPrecedence',
    4 => 'setQosGroup',
    5 => 'drop',
    6 => 'setAtmClp',
    7 => 'setDiscardClass'
    };

my $truthValueTranslation = {
    1 => 'enabled',
    2 => 'disabled'
    };

my $queueUnitTranslation = {
    1 => 'packets',
    2 => 'cells',
    3 => 'bytes'
    };


my %cbQosValueTranslation =
    (
     'IfType' => {
         1 => 'mainInterface',
         2 => 'subInterface' },
  
     'PolicyDirection' => {
         1 => 'input',
         2 => 'output' },

     'ObjectsType' => {
         1 => 'policymap',
         2 => 'classmap',
         3 => 'matchStatement',
         4 => 'queueing',
         5 => 'randomDetect',
         7 => 'police',
         8 => 'set' },

     'CMInfo' => {
         1 => 'none',
         2 => 'all',
         3 => 'any'
         },
     
     'QueueingCfgBandwidthUnits'   => {
         1 => 'kbps',
         2 => 'percent',
         3 => 'percent_remaining'
         },
     
     'WREDClassCfgThresholdUnit'    => $queueUnitTranslation,
     
     'QueueingCfgFlowEnabled'      => $truthValueTranslation,
     'QueueingCfgPriorityEnabled'  => $truthValueTranslation,

     'QueueingCfgQLimitUnits'      => $queueUnitTranslation,
    
        
     'PoliceCfgConformAction'  => $policyActionTranslation,
     'PoliceCfgExceedAction'   => $policyActionTranslation,
     'PoliceCfgViolateAction'  => $policyActionTranslation
     );

sub translateCbQoSValue
{
    my $value = shift;
    my $name = shift;

    # Chop heading and trailing space
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;

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


my %dscpValueTranslation =
    (
     'CS1'  => 8,
     'AF11' => 10,
     'AF12' => 12,
     'AF13' => 14,
     'CS2'  => 16,
     'AF21' => 18,
     'AF22' => 20,
     'AF23' => 22,
     'CS3'  => 24,
     'AF31' => 26,
     'AF32' => 28,
     'AF33' => 30,
     'CS4'  => 32,
     'AF41' => 34,
     'AF42' => 36,
     'AF43' => 38,
     'CS5'  => 40,
     'EF'   => 46,
     'CS6'  => 48,
     'CS7'  => 56
     );

sub translateDscpValue
{
    my $value = shift;
    
    if( $value =~ /[a-zA-Z]/ )
    {
        my $val = uc $value;
        if( not defined( $dscpValueTranslation{$val} ) )
        {
            Error('Cannot translate DSCP value: ' . $value );
            $value = 0;
        }
        else
        {
            $value = $dscpValueTranslation{$val};
        }
    }
    return $value;
}


1;


# Local Variables:
# mode: perl
# indent-tabs-mode: nil
# perl-indent-level: 4
# End:
