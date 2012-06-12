push( @Torrus::DevDiscover::loadModules,
      'Torrus::DevDiscover::OneOS_cbQoS' );

# List of default DSCP values to be monitored for RED statistics.
# May be redefined in devdiscover-siteconfig.pl, or in DDX parameter:
# <param name="OneOS_cbQoS::red-dscp-values" value="0,AF21,AF22,AF23,EF"/>

@Torrus::DevDiscover::OneOS_cbQoS::RedDscpValues =
    qw(0 AF21 AF22 AF31 AF32 AF41 AF42 EF);


$Torrus::ConfigBuilder::templateRegistry{
    'OneOS_cbQoS::oneaccess-cbqos-subtree'} = {
        'name'   => 'oneaccess-cbqos-subtree',
        'source' => 'vendor/oneaccess.oneos.cbqos.xml'
        };

$Torrus::ConfigBuilder::templateRegistry{
    'OneOS_cbQoS::oneaccess-cbqos-policymap-subtree'} = {
        'name'   => 'oneaccess-cbqos-policymap-subtree',
        'source' => 'vendor/oneaccess.oneos.cbqos.xml'
        };
    
$Torrus::ConfigBuilder::templateRegistry{
    'OneOS_cbQoS::oneaccess-cbqos-classmap-meters'} = {
        'name'   => 'oneaccess-cbqos-classmap-meters',
        'source' => 'vendor/oneaccess.oneos.cbqos.xml'
        };

$Torrus::ConfigBuilder::templateRegistry{
    'OneOS_cbQoS::oneaccess-cbqos-match-stmt-meters'} = {
        'name'   => 'oneaccess-cbqos-match-stmt-meters',
        'source' => 'vendor/oneaccess.oneos.cbqos.xml'
        };

$Torrus::ConfigBuilder::templateRegistry{
    'OneOS_cbQoS::oneaccess-cbqos-police-meters'} = {
        'name'   => 'oneaccess-cbqos-police-meters',
        'source' => 'vendor/oneaccess.oneos.cbqos.xml'
        };

$Torrus::ConfigBuilder::templateRegistry{
    'OneOS_cbQoS::oneaccess-cbqos-queueing-meters'} = {
        'name'   => 'oneaccess-cbqos-queueing-meters',
        'source' => 'vendor/oneaccess.oneos.cbqos.xml'
        };

$Torrus::ConfigBuilder::templateRegistry{
    'OneOS_cbQoS::oneaccess-cbqos-red-subtree'} = {
        'name'   => 'oneaccess-cbqos-red-subtree',
        'source' => 'vendor/oneaccess.oneos.cbqos.xml'
        };

$Torrus::ConfigBuilder::templateRegistry{
    'OneOS_cbQoS::oneaccess-cbqos-red-meters'} = {
        'name'   => 'oneaccess-cbqos-red-meters',
        'source' => 'vendor/oneaccess.oneos.cbqos.xml'
        };

1;
