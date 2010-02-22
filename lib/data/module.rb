module Carat::Data
  class ModuleClass < ObjectClass
    def new(name)
      ModuleInstance.new(runtime, self, name)
    end
  end
  
  class ModuleInstance < ObjectInstance
    attr_reader   :name, :method_table
    
    def initialize(runtime, klass, name = nil)
      @name         = name
      @method_table = {}
      
      super(runtime, klass)
      
      include_module_primitives if include_class?
      create_singleton_class unless include_class? || singleton?
    end
    
    def singleton?
      instance_of?(SingletonClassInstance)
    end
    
    def include_class?
      instance_of?(IncludeClassInstance)
    end
    
    # If this is actually a module (as opposed to a class or whatever) then we can have a module
    # in the implementation language containing primitives for this specific module in the target
    # language.
    # 
    # For instance, if we create a +ModuleInstance+ with name "Kernel", then the module named
    # "KernelModule", defined primitives for it.
    # 
    # This is useful, because then when "Kernel" is included in another module/class, we can also
    # make the primitives available to the module/class it is included in. 
    def primitives_module
      if name && Carat::Data.const_defined?("#{name}Module")
        Carat::Data.const_get("#{name}Module")
      end
    end
    
    def to_s
      "<module:#{name}>"
    end
    
    private
      
      def include_module_primitives
        extend(primitives_module) if primitives_module
      end
    
    public
    
    # ***** Primitives ***** #
    
    def primitive_name
      yield constants[:String].new(name)
    end
  end
end
