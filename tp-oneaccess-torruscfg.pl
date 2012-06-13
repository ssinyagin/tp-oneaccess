push( @Torrus::Collector::loadModules,
      'Torrus::Collector::OneAccess_QoS' );

push( @Torrus::Validator::loadLeafValidators,
      'Torrus::Collector::OneAccess_QoS_Params' );

1;
