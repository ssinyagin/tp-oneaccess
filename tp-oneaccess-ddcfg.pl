push( @Torrus::DevDiscover::loadModules,
      'Torrus::DevDiscover::OneAccess',
      'Torrus::DevDiscover::OneAccess_QoS',
      );

# List of default DSCP values to be monitored for RED statistics.
# May be redefined in devdiscover-siteconfig.pl, or in DDX parameter:
# <param name="OneAccess_QoS::red-dscp-values" value="0,AF21,AF22,AF23,EF"/>

@Torrus::DevDiscover::OneAccess_QoS::RedDscpValues =
    qw(0 AF21 AF22 AF31 AF32 AF41 AF42 EF);


$Torrus::ConfigBuilder::templateRegistry{
    'OneAccess_QoS::oneaccess-cbqos-subtree'} = {
        'name'   => 'oneaccess-cbqos-subtree',
        'source' => 'vendor/oneaccess.qos.xml'
        };

$Torrus::ConfigBuilder::templateRegistry{
    'OneAccess_QoS::oneaccess-cbqos-policymap-subtree'} = {
        'name'   => 'oneaccess-cbqos-policymap-subtree',
        'source' => 'vendor/oneaccess.qos.xml'
        };
    
$Torrus::ConfigBuilder::templateRegistry{
    'OneAccess_QoS::oneaccess-cbqos-classmap-meters'} = {
        'name'   => 'oneaccess-cbqos-classmap-meters',
        'source' => 'vendor/oneaccess.qos.xml'
        };

$Torrus::ConfigBuilder::templateRegistry{
    'OneAccess_QoS::oneaccess-cbqos-match-stmt-meters'} = {
        'name'   => 'oneaccess-cbqos-match-stmt-meters',
        'source' => 'vendor/oneaccess.qos.xml'
        };

$Torrus::ConfigBuilder::templateRegistry{
    'OneAccess_QoS::oneaccess-cbqos-police-meters'} = {
        'name'   => 'oneaccess-cbqos-police-meters',
        'source' => 'vendor/oneaccess.qos.xml'
        };

$Torrus::ConfigBuilder::templateRegistry{
    'OneAccess_QoS::oneaccess-cbqos-queueing-meters'} = {
        'name'   => 'oneaccess-cbqos-queueing-meters',
        'source' => 'vendor/oneaccess.qos.xml'
        };

$Torrus::ConfigBuilder::templateRegistry{
    'OneAccess_QoS::oneaccess-cbqos-red-subtree'} = {
        'name'   => 'oneaccess-cbqos-red-subtree',
        'source' => 'vendor/oneaccess.qos.xml'
        };

$Torrus::ConfigBuilder::templateRegistry{
    'OneAccess_QoS::oneaccess-cbqos-red-meters'} = {
        'name'   => 'oneaccess-cbqos-red-meters',
        'source' => 'vendor/oneaccess.qos.xml'
        };

1;
