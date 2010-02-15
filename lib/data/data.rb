module Carat
  module Data
    # First, very clearly specify the basic hierarchy of data classes. This mirrors the inheritance
    # hierarchy in the target language:
    # 
    #   class Object         < nil;    end
    #   class Module         < Object; end
    #   class Class          < Module; end
    #   class SingletonClass < Class;  end
    # 
    class ObjectInstance; end
    
    class ModuleInstance         < ObjectInstance; end
    class ClassInstance          < ModuleInstance; end
    class SingletonClassInstance < ClassInstance;  end
    
    class ObjectClass            < ClassInstance;  end
    class ModuleClass            < ObjectClass;    end
    class ClassClass             < ModuleClass;    end
    class SingletonClassClass    < ClassClass;     end
    
    # Now, require the actual code
    require DATA_PATH + '/kernel'
    require DATA_PATH + '/object'
    require DATA_PATH + '/module'
    require DATA_PATH + '/class'
    
    require DATA_PATH + '/singleton_class'
    require DATA_PATH + '/include_class'
    
    require DATA_PATH + '/lambda'
    require DATA_PATH + '/method'
    require DATA_PATH + '/primitive'
    require DATA_PATH + '/exception'
    
    require DATA_PATH + '/fixnum'
    require DATA_PATH + '/array'
    require DATA_PATH + '/string'
    require DATA_PATH + '/singletons'
  end
end
