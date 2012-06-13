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
     'oacQosServicePolicyTable'         => '1.3.6.1.4.1.13191.10.3.1.3.1',
     'oacQosPolicyIndex'                => '1.3.6.1.4.1.13191.10.3.1.3.1.1.1',
     'oacQosIfIndex'                    => '1.3.6.1.4.1.13191.10.3.1.3.1.1.2',
     'oacQosIfType'                     => '1.3.6.1.4.1.13191.10.3.1.3.1.1.3',
     'oacQosPolicyDirection'            => '1.3.6.1.4.1.13191.10.3.1.3.1.1.4',
     'oacQosObjectsTable'               => '1.3.6.1.4.1.13191.10.3.1.3.3',
     'oacQosObjectsIndex'               => '1.3.6.1.4.1.13191.10.3.1.3.3.1.1',
     'oacQosConfigIndex'                => '1.3.6.1.4.1.13191.10.3.1.3.3.1.2',
     'oacQosObjectsType'                => '1.3.6.1.4.1.13191.10.3.1.3.3.1.3',
     'oacQosParentObjectsIndex'         => '1.3.6.1.4.1.13191.10.3.1.3.3.1.4',

     'oacQosPolicyMapCfgTable'          => '1.3.6.1.4.1.13191.10.3.1.3.4',
     'oacQosPolicyMapName'              => '1.3.6.1.4.1.13191.10.3.1.3.4.1.1',
 
     'oacQosCMCfgTable'                 => '1.3.6.1.4.1.13191.10.3.1.3.5',
     'oacQosCMName'                     => '1.3.6.1.4.1.13191.10.3.1.3.5.1.1',
     'oacQosCMInfo'                     => '1.3.6.1.4.1.13191.10.3.1.3.5.1.2',

     'oacQosMatchCfgTable'              => '1.3.6.1.4.1.13191.10.3.1.3.7',
     'oacQosMatchName'                  => '1.3.6.1.4.1.13191.10.3.1.3.7.1.1',
     'oacQosMatchInfo'                  => '1.3.6.1.4.1.13191.10.3.1.3.7.1.2',

     'oacQosQueueingCfgTable'           => '1.3.6.1.4.1.13191.10.3.1.3.16',
     'oacQosQueueingCfgFlowEnabled'     => '1.3.6.1.4.1.13191.10.3.1.3.16.1.1',
     'oacQosQueueingCfgPriorityEnabled' => '1.3.6.1.4.1.13191.10.3.1.3.16.1.2',
     'oacQosQueueingCfgBandwidth'       => '1.3.6.1.4.1.13191.10.3.1.3.16.1.3',
     'oacQosQueueingCfgBandwidthUnits'  => '1.3.6.1.4.1.13191.10.3.1.3.16.1.4',
     'oacQosQueueingCfgAggregateQSize'  => '1.3.6.1.4.1.13191.10.3.1.3.16.1.5',
     'oacQosQueueingCfgDynamicQNumber'  => '1.3.6.1.4.1.13191.10.3.1.3.16.1.6',
     'oacQosQueueingCfgPrioBurstSize'   => '1.3.6.1.4.1.13191.10.3.1.3.16.1.7',
     'oacQosQueueingCfgQLimitUnits'     => '1.3.6.1.4.1.13191.10.3.1.3.16.1.8',
     'oacQosQueueingCfgAggregateQLimit' => '1.3.6.1.4.1.13191.10.3.1.3.16.1.9',
  
     'oacQosWREDCfgTable'              => '1.3.6.1.4.1.13191.10.3.1.3.13',
     'oacQosWREDCfgExponWeight'        => '1.3.6.1.4.1.13191.10.3.1.3.13.1.1',
     'oacQosWREDCfgDscpPrec'           => '1.3.6.1.4.1.13191.10.3.1.3.13.1.2',
     'oacQosWREDCfgECNEnabled'         => '1.3.6.1.4.1.13191.10.3.1.3.13.1.3',
     'oacQosWREDClassCfgTable'         => '1.3.6.1.4.1.13191.10.3.1.3.14',
     'oacQosWREDValue'                 => '1.3.6.1.4.1.13191.10.3.1.3.14.1.1',
     'oacQosWREDCfgPktDropProb'        => '1.3.6.1.4.1.13191.10.3.1.3.14.1.2',
     'oacQosWREDClassCfgThresholdUnit' => '1.3.6.1.4.1.13191.10.3.1.3.14.1.3',
     'oacQosWREDClassCfgMinThreshold'  => '1.3.6.1.4.1.13191.10.3.1.3.14.1.4',
     'oacQosWREDClassCfgMaxThreshold'  => '1.3.6.1.4.1.13191.10.3.1.3.14.1.5',

     'oacQosPoliceCfgTable'            => '1.3.6.1.4.1.13191.10.3.1.3.10',
     'oacQosPoliceCfgCIR'              => '1.3.6.1.4.1.13191.10.3.1.3.10.1.1',
     'oacQosPoliceCfgCIR64'            => '1.3.6.1.4.1.13191.10.3.1.3.10.1.2',
     'oacQosPoliceCfgBurstSize'        => '1.3.6.1.4.1.13191.10.3.1.3.10.1.3',
     'oacQosPoliceCfgPIR'              => '1.3.6.1.4.1.13191.10.3.1.3.10.1.4',
     'oacQosPoliceCfgExtBurstSize'     => '1.3.6.1.4.1.13191.10.3.1.3.10.1.5',
     'oacQosPoliceCfgConformAction'    => '1.3.6.1.4.1.13191.10.3.1.3.10.1.6',
     'oacQosPoliceCfgConformSetValue'  => '1.3.6.1.4.1.13191.10.3.1.3.10.1.7',
     'oacQosPoliceCfgExceedAction'     => '1.3.6.1.4.1.13191.10.3.1.3.10.1.8',
     'oacQosPoliceCfgExceedSetValue'   => '1.3.6.1.4.1.13191.10.3.1.3.10.1.9',
     'oacQosPoliceCfgViolateAction'    => '1.3.6.1.4.1.13191.10.3.1.3.10.1.10',
     'oacQosPoliceCfgViolateSetValue'  => '1.3.6.1.4.1.13191.10.3.1.3.10.1.11'
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
     'policymap'       => ['oacQosPolicyMapCfgTable'],
     'classmap'        => ['oacQosCMCfgTable'],
     'matchStatement'  => ['oacQosMatchCfgTable'],
     'queueing'        => ['oacQosQueueingCfgTable'],
     'randomDetect'    => ['oacQosWREDCfgTable', 'oacQosWREDClassCfgTable'],
     'police'          => ['oacQosoacQosPoliceCfgTable']
     );


sub checkdevtype
{
    my $dd = shift;
    my $devdetails = shift;

    my $session = $dd->session();

    # QoS templates use 64-bit counters, so SNMPv1 is explicitly unsupported
    
    if( $devdetails->isDevType('OneAccess') and
        $devdetails->param('snmp-version') ne '1' and
        $dd->checkSnmpTable('oacQosServicePolicyTable') )
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

    # Process oacQosServicePolicyTable

    $data->{'cbqos_policies'} = {};
    
    foreach my $entryName ('oacQosIfIndex','oacQosIfType',
                           'oacQosPolicyDirection')
    {
        my $table = $dd->walkSnmpTable($entryName);
        while( my($policyIndex, $value) = each %{$table} )
        {
            $value = translateCbQoSValue( $value, $entryName );
            $data->{'cbqos_policies'}{$policyIndex}{$entryName} = $value;
        }
    }


    # Process ObjectsTable
    $data->{'cbqos_objects'} = {};
    $data->{'cbqos_children'} = {};

    my $oacQosObjectsType = $dd->walkSnmpTable('oacQosObjectsType');

    if( scalar(keys %{$oacQosObjectsType}) == 0 )
    {
        return 1;
    }
    
    while( my($INDEX, $value) = each %{$oacQosObjectsType} )
    {
        $data->{'cbqos_objects'}{$INDEX}{'oacQosObjectsType'} =
            translateCbQoSValue( $value, 'oacQosObjectsType' );
    }

    my $oacQosConfigIndex =
        $dd->walkSnmpTable('oacQosConfigIndex');
    my $oacQosParentObjectsIndex =
        $dd->walkSnmpTable('oacQosParentObjectsIndex');
    
    my $needTables = {};

    foreach my $INDEX (keys %{$data->{'cbqos_objects'}})
    {
        my ($policyIndex, $objectIndex) = split(/\./o, $INDEX);

        if( not exists( $data->{'cbqos_policies'}{$policyIndex} ) )
        {
            delete $data->{'cbqos_objects'}{$INDEX};
            next;
        }

        my $object = $data->{'cbqos_objects'}{$INDEX};
        $object->{'oacQosPolicyIndex'} = $policyIndex;
        $object->{'oacQosConfigIndex'} = $oacQosConfigIndex->{$INDEX};

        my $objType = $object->{'oacQosObjectsType'};

        # Store only objects of supported types
        my $takeit = $supportedObjectTypes{$objType};

        # Suppress unneeded objects
        if( $takeit and
            $devdetails->paramEnabled('OneAccess_QoS::classmaps-only')
            and
            $objType ne 'policymap' and
            $objType ne 'classmap' )
        {
            $takeit = 0;
        }
        
        if( $takeit and
            $devdetails->paramEnabled
            ('OneAccess_QoS::suppress-match-statements')
            and
            $objType eq 'matchStatement' )
        {
            $takeit = 0;
        }

        if( $takeit )
        {
            # Store the hierarchy information
            my $parent = $oacQosParentObjectsIndex->{$INDEX};
            if( $parent ne '0' )
            {
                $parent = $policyIndex .'.'. $parent;
            }
                
            if( not exists( $data->{'cbqos_children'}{$parent} ) )
            {
                $data->{'cbqos_children'}{$parent} = [];
            }
            push( @{$data->{'cbqos_children'}{$parent}},
                  $policyIndex .'.'. $objectIndex );

            foreach my $tableName
                ( @{$cfgTablesForType{$object->{'oacQosObjectsType'}}} )
            {
                $needTables->{$tableName} = 1;
            }
        }
        else
        {
            delete $data->{'cbqos_objects'}{$INDEX};
        }
    }


    # Prepare the list of DSCP values for RED
    my @dscpValues =
        split(',',
              $devdetails->paramString('OneAccess_QoS::red-dscp-values'));
    
    if( scalar(@dscpValues) == 0 )
    {
        @dscpValues = @Torrus::DevDiscover::OneAccess_QoS::RedDscpValues;
    }

    my $maxrepetitions = $devdetails->param('snmp-maxrepetitions');
    my $cfgData = {};
    
    # Retrieve needed SNMP tables
    foreach my $tableName ( keys %{$needTables} )
    {
        my $table =
            $session->get_table( -baseoid => $dd->oiddef($tableName),
                                 -maxrepetitions => $maxrepetitions );
        if( defined( $table ) )
        {
            while( my($oid, $val) = each %{$table} )
            {
                $cfgData->{$oid} = $val;
            }
        }
        elsif( not $cfgTablesOptional{$tableName} )
        {
            Error('Error retrieving ' . $tableName);
            return 0;
        }
    }

    
    # Process oacQoSxxxCfgTable
    $data->{'cbqos_objcfg'} = {};
                
    while( my( $policyObjectIndex, $objectRef ) =
           each %{$data->{'cbqos_objects'}} )  
    {
        my $objConfIndex = $objectRef->{'oacQosConfigIndex'};
        my $objType = $objectRef->{'oacQosObjectsType'};
        my $object = {};
        my @rows = ();
       
        # sometimes configuration changes leave garbage like objects
        # with empty configuration.        
        my %mandatory; 

        if( $objType eq 'policymap' )
        {
            push( @rows, 'oacQosPolicyMapName');
            $mandatory{'oacQosPolicyMapName'} = 1;
        }
        elsif( $objType eq 'classmap' )
        {
            push( @rows, 'cbQosCMName', 'cbQosCMInfo' );
            $mandatory{'cbQosCMName'} = 1;
        }
        elsif( $objType eq 'matchStatement' )
        {
            push( @rows, 'oacQosMatchName' );
            $mandatory{'oacQosMatchName'} = 1;
        }
        elsif( $objType eq 'queueing' )
        {
            push( @rows,
                  'oacQosQueueingCfgFlowEnabled',
                  'oacQosQueueingCfgPriorityEnabled',
                  'oacQosQueueingCfgBandwidth',
                  'oacQosQueueingCfgBandwidthUnits',
                  'oacQosQueueingCfgAggregateQSize',
                  'oacQosQueueingCfgDynamicQNumber',
                  'oacQosQueueingCfgPrioBurstSize',
                  'oacQosQueueingCfgQLimitUnits',
                  'oacQosQueueingCfgAggregateQLimit');
            $mandatory{'oacQosQueueingCfgBandwidth'} = 1;
            $mandatory{'oacQosQueueingCfgBandwidthUnits'} = 1;
        }
        elsif( $objType eq 'randomDetect')
        {
            push( @rows,
                  'oacQosWREDCfgExponWeight',
                  'oacQosWREDCfgDscpPrec',
                  'oacQosWREDCfgECNEnabled' );
            $mandatory{'oacQosWREDCfgExponWeight'} = 1;
        }

        elsif( $objType eq 'police' )
        {
            push( @rows,
                  'oacQosPoliceCfgCIR',
                  'oacQosPoliceCfgCIR64',
                  'oacQosPoliceCfgBurstSize',
                  'oacQosPoliceCfgPIR',
                  'oacQosPoliceCfgExtBurstSize',
                  'oacQosPoliceCfgConformAction',
                  'oacQosPoliceCfgConformSetValue',
                  'oacQosPoliceCfgExceedAction',
                  'oacQosPoliceCfgExceedSetValue',
                  'oacQosPoliceCfgViolateAction',
                  'oacQosPoliceCfgViolateSetValue');
            $mandatory{'oacQosPoliceCfgCIR'} = 1;
        }
        else
        {
            Error('Unsupported object type: ' . $objType);
        }

        foreach my $row ( @rows )
        {
            my $value = $cfgData->{$dd->oiddef($row) .'.'. $objConfIndex};
            if( defined($value) and $value ne '' )
            {
                $value = translateCbQoSValue( $value, $row );
                $data->{'cbqos_objcfg'}{$objConfIndex}{$row} = $value;
            }
            elsif( $mandatory{$row} )
            {
                Warn('Object with missing mandatory configuration: ' .
                     'oacQosPolicyIndex=' .
                     $objectRef->{'oacQosPolicyIndex'} .
                     ', oacQosObjectsIndex=' . $policyObjectIndex);
                delete $data->{'cbqos_objects'}{$policyObjectIndex};
                $objType = 'DELETED';
            }
        }
   
        # In addition, get per-DSCP RED configuration
        if( $objType eq 'randomDetect')
        {
            foreach my $dscp ( @dscpValues )
            {
                foreach my $row ( qw(oacQosWREDCfgPktDropProb
                                     oacQosWREDClassCfgThresholdUnit
                                     oacQosWREDClassCfgMinThreshold
                                     oacQosWREDClassCfgMaxThreshold) )
                {
                    my $dscpN = translateDscpValue( $dscp );
                    my $value = $cfgData->{$dd->oiddef($row) .
                                               '.' . $objConfIndex .
                                               '.' . $dscpN);
                    if( defined($value) and $value ne '' )
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
                         ['OneAccess_QoS::oneaccess-cbqos-subtree']);
   
    # Recursively build a subtree for every policy

    buildChildrenConfigs( $data, $cb, $topNode, '0', '', '' );
    return;
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
        my $objConfIndex  = $objectRef->{'oacQosConfigIndex'};
        my $objType       = $objectRef->{'oacQosObjectsType'};
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
            $objectName = $configRef->{'oacQosPolicyMapName'};

            my $policyRef = $data->{'cbqos_policies'}{$objectIndex};
            if( ref( $policyRef ) )
            {
                my $ifIndex    = $policyRef->{'oacQosIfIndex'};
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
                    
                    my $ifType = $policyRef->{'oacQosIfType'};
                    $param->{'cbqos-interface-type'} = $ifType;
                    
                    my $direction = $policyRef->{'oacQosPolicyDirection'};
                    
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
                    if( defined($ifComment) and $ifComment ne '' )
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
                  'OneAccess_QoS::oneaccess-cbqos-policymap-subtree' );
        }
        elsif( $objType eq 'classmap' )
        {
            $objectName = $configRef->{'oacQosCMName'};
            $subtreeName = $objectName;
            $subtreeComment = 'Class: ' . $objectName;
            $objectNick = 'cm_' . $objectName;
            $param->{'cbqos-class-map-name'} = $objectName;
            push( @templates,
                  'OneAccess_QoS::oneaccess-cbqos-classmap-meters' );

            $param->{'legend'} =
                sprintf('Match: %s;', $configRef->{'oacQosCMInfo'});
    
        }
        elsif( $objType eq 'matchStatement' )
        {
            my $name = $configRef->{'oacQosMatchName'};
            $subtreeName = $name;
            $subtreeComment = 'Match statement statistics';
           $objectNick = 'ms_' . $name;
            $param->{'cbqos-match-statement-name'} = $name;
            push( @templates,
                  'OneAccess_QoS::oneaccess-cbqos-match-stmt-meters' );
        }
        elsif( $objType eq 'queueing' )
        {
            my $bandwidth = $configRef->{'oacQosQueueingCfgBandwidth'};
            my $units = $configRef->{'oacQosQueueingCfgBandwidthUnits'};

            $subtreeName = 'Bandwidth_' . $bandwidth . '_' . $units;
            $subtreeComment = 'Queueing statistics';
            $objectNick = 'qu_' . $bandwidth;
            $param->{'cbqos-queueing-bandwidth'} = $bandwidth;
            push( @templates,
                  'OneAccess_QoS::oneaccess-cbqos-queueing-meters' );

            $param->{'legend'} =
                sprintf('Guaranteed Bandwidth: %d %s;' .
                        'Flow: %s;' .
                        'Priority: %s;',                        
                        $bandwidth, $units,                        
                        $configRef->{'oacQosQueueingCfgFlowEnabled'},
                        $configRef->{'oacQosQueueingCfgPriorityEnabled'});

            if( defined( $configRef->{'oacQosQueueingCfgAggregateQLimit'} ) )
            {
                $param->{'legend'} .=
                    sprintf('Max Queue Size: %d %s;',
                            $configRef->{'oacQosQueueingCfgAggregateQLimit'},
                            $configRef->{'oacQosQueueingCfgQLimitUnits'});
            }
            elsif( defined( $configRef->{'oacQosQueueingCfgAggregateQSize'} ) )
            {
                $param->{'legend'} .=
                    sprintf('Max Queue Size: %d packets;',
                            $configRef->{'oacQosQueueingCfgAggregateQSize'});
            }
    
            if( $configRef->{'oacQosQueueingCfgDynamicQNumber'} > 0 )
            {
                $param->{'legend'} .=
                    sprintf('Max Dynamic Queues: %d;',
                            $configRef->{'oacQosQueueingCfgDynamicQNumber'});
            }

            if( $configRef->{'oacQosQueueingCfgPrioBurstSize'} > 0 )
            {
                $param->{'legend'} .=
                    sprintf('Priority Burst Size: %d bytes;',
                            $configRef->{'oacQosQueueingCfgPrioBurstSize'});
            }
        }
        elsif( $objType eq 'randomDetect')
        {
            $subtreeName = 'WRED';
            $subtreeComment = 'Weighted Random Early Detect Statistics';
            $param->{'legend'} =
                sprintf('Exponential Weight: %d;',
                        $configRef->{'oacQosWREDCfgExponWeight'});
            push( @templates,
                  'OneAccess_QoS::oneaccess-cbqos-red-subtree' );

            if( $configRef->{'oacQosWREDCfgDscpPrec'} == 1 )
            {
                Error('Precedence-based WRED is not supported');
            }
        }

        elsif( $objType eq 'police' )
        {
            my $rate = $configRef->{'oacQosPoliceCfgCIR'};
            $subtreeName = sprintf('Police_%d_bps', $rate );
            $subtreeComment = 'Rate policing statistics';
            $objectNick = 'p_' . $rate;
            $param->{'cbqos-police-rate'} = $rate;
            push( @templates,
                  'OneAccess_QoS::oneaccess-cbqos-police-meters' );

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
                        $configRef->{'oacQosPoliceCfgBurstSize'},
                        $configRef->{'oacQosPoliceCfgExtBurstSize'},
                        $configRef->{'oacQosPoliceCfgConformAction'},
                        $configRef->{'oacQosPoliceCfgConformSetValue'},
                        $configRef->{'oacQosPoliceCfgExceedAction'},
                        $configRef->{'oacQosPoliceCfgExceedSetValue'},
                        $configRef->{'oacQosPoliceCfgViolateAction'},
                        $configRef->{'oacQosPoliceCfgViolateSetValue'});
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

                    if( defined( $cfg->{'oacQosWREDClassCfgThresholdUnit'} ) )
                    {
                        $param->{'legend'} =
                            sprintf('Min Threshold: %d %s;' .
                                    'Max Threshold: %d %s;',
                                    $cfg->{'oacQosWREDClassCfgMinThreshold'},
                                    $cfg->{'oacQosWREDClassCfgThresholdUnit'},
                                    $cfg->{'oacQosWREDClassCfgMaxThreshold'},
                                    $cfg->{'oacQosWREDClassCfgThresholdUnit'});
                    }
                    else
                    {
                        $param->{'legend'} =
                            sprintf('Min Threshold: %d packets;' .
                                    'Max Threshold: %d packets;',
                                    $cfg->{'oacQosWREDCfgMinThreshold'},
                                    $cfg->{'oacQosWREDCfgMaxThreshold'});
                    }
                    
                    $cb->addSubtree
                        ( $objectNode, $dscp, $param,
                          ['OneAccess_QoS::oneaccess-cbqos-red-meters'] );
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
    return;
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


my %oacQosValueTranslation =
    (
     'IfType' => {
         1 => 'mainInterface',
         2 => 'subInterface' },
  
     'oacQosPolicyDirection' => {
         1 => 'input',
         2 => 'output' },

     'oacQosObjectsType' => {
         1 => 'policymap',
         2 => 'classmap',
         3 => 'matchStatement',
         4 => 'queueing',
         5 => 'randomDetect',
         7 => 'police',
         8 => 'set' },

     'cbQosCMInfo' => {
         1 => 'none',
         2 => 'all',
         3 => 'any'
         },
     
     'oacQosQueueingCfgBandwidthUnits'   => {
         1 => 'kbps',
         2 => 'percent',
         3 => 'percent_remaining'
         },
     
     'oacQosWREDClassCfgThresholdUnit'    => $queueUnitTranslation,
     
     'oacQosQueueingCfgFlowEnabled'      => $truthValueTranslation,
     'oacQosQueueingCfgPriorityEnabled'  => $truthValueTranslation,

     'oacQosQueueingCfgQLimitUnits'      => $queueUnitTranslation,
    
        
     'oacQosPoliceCfgConformAction'  => $policyActionTranslation,
     'oacQosPoliceCfgExceedAction'   => $policyActionTranslation,
     'oacQosPoliceCfgViolateAction'  => $policyActionTranslation
     );

sub translateCbQoSValue
{
    my $value = shift;
    my $name = shift;

    # Chop heading and trailing space
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;

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
