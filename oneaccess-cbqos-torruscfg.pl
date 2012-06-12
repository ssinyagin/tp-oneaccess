push( @Torrus::Collector::loadModules,
      'Torrus::Collector::OneOS_cbQoS' );

push( @Torrus::Validator::loadLeafValidators,
      'Torrus::Collector::OneOS_cbQoS_Params' );

1;
