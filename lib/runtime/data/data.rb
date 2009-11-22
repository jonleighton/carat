class Carat::Runtime
  # Code for dealing with primitives
  require Carat::DATA_PATH + '/primitive'
  require Carat::DATA_PATH + '/primitive_host'
  
  # First, very clearly specify the basic hierarchy of data classes...
  
  class ObjectInstance
    # All objects can have primitives
    extend PrimitiveHost
  end
  
  class ModuleInstance < ObjectInstance; end
  class ClassInstance  < ModuleInstance; end
  class ObjectClass    < ClassInstance;  end
  class ModuleClass    < ClassInstance;  end
  class ClassClass     < ClassInstance;  end
  
  # Now, require the actual code
  require Carat::DATA_PATH + '/kernel'
  
  require Carat::DATA_PATH + '/object'
  require Carat::DATA_PATH + '/module'
  require Carat::DATA_PATH + '/class'
  
  require Carat::DATA_PATH + '/singleton_class'
  require Carat::DATA_PATH + '/meta_class'
  require Carat::DATA_PATH + '/include_class'
  
  require Carat::DATA_PATH + '/method'
  
  require Carat::DATA_PATH + '/fixnum'
  require Carat::DATA_PATH + '/array'
end
