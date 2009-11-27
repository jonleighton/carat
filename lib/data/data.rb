module Carat
  module Data
    # First, very clearly specify the basic hierarchy of data classes...
    class ObjectInstance; end
    class ModuleInstance < ObjectInstance; end
    class ClassInstance  < ModuleInstance; end
    class ObjectClass    < ClassInstance;  end
    class ModuleClass    < ClassInstance;  end
    class ClassClass     < ClassInstance;  end
    
    # Now, require the actual code
    require DATA_PATH + '/primitive'
    require DATA_PATH + '/primitive_host'
    
    require DATA_PATH + '/object'
    require DATA_PATH + '/module'
    require DATA_PATH + '/class'
    
    require DATA_PATH + '/singleton_class'
    require DATA_PATH + '/meta_class'
    require DATA_PATH + '/include_class'
    
    require DATA_PATH + '/method'
    
    require DATA_PATH + '/kernel'
    require DATA_PATH + '/fixnum'
    require DATA_PATH + '/array'
    require DATA_PATH + '/string'
    require DATA_PATH + '/proc'
    require DATA_PATH + '/nil_class'
    require DATA_PATH + '/true_class'
    require DATA_PATH + '/false_class'
  end
end
