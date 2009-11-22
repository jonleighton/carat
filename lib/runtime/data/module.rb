class Carat::Runtime
  class ModuleClass < ClassInstance
    
  end
  
  class ModuleInstance < ObjectInstance
    attr_reader :name
    attr_accessor :super
    attr_writer :method_table, :instance_class
    
    # Any Object can have a singleton_class, but we can use the alias "metaclass" if we want to make
    # it explicit that the singleton class is specifically a metaclass
    alias_method :metaclass, :singleton_class
    
    def initialize(runtime, name = nil)
      @name = name
      super(runtime, get_klass(runtime))
      
      include_module_primitives if instance_of?(ModuleInstance)
      add_primitives_to_method_table if runtime.initialized?
    end
    
    # Modules have a metaclass so that they can have module methods. The class of the metaclass is
    # always +Module+.
    def get_klass(runtime)
      MetaClassInstance.new(runtime, self, runtime.constants[:Module])
    end
    
    # If this is actually a module (as opposed to a class or whatever) then we can have an object-
    # language module containing primitives for this specific module in the meta-language. For
    # instance, if we create a +ModuleInstance+ with name "Kernel", then the module named
    # "KernelModule", defined primitives for it.
    # 
    # This is useful, because then when "Kernel" is included in another module/class, we can also
    # make the primitives available to the module/class it is included in. 
    def primitives_module
      if name && Carat::Runtime.const_defined?("#{name}Module")
        Carat::Runtime.const_get("#{name}Module")
      end
    end
    
    def include_module_primitives
      (class << self; self; end).send(:include, primitives_module) if primitives_module
    end
    
    # Returns the class which is used to represent an instance of this class.
    # 
    # For example, if this class is +FixnumClass+, the +instance_class+ will be +FixnumInstance+
    # 
    # TODO: Should this really be defined in Module?
    def instance_class
      @instance_class ||= begin
        class_name = self.class.to_s.sub(/^.*\:\:/, '')
        instance_class_name = class_name.sub(/Class$/, "Instance")
        
        if class_name !~ /Instance$/ && Carat::Runtime.const_defined?(instance_class_name)
          Carat::Runtime.const_get(instance_class_name)
        else
          Carat::Runtime::ObjectInstance
        end
      end
    end
    
    def add_primitives_to_method_table
      method_table.merge!(instance_class.primitives)
    end
    
    def ancestors
      [self] + (self.super && self.super.ancestors || [])
    end
    
    # The methods available to instances
    def method_table
      @method_table ||= {}
    end
    
    def lookup_method(name)
      method_table[name] || (self.super && self.super.lookup_method(name))
    end
    
    def singleton?
      false
    end
    
    def to_s
      "<module:#{name}>"
    end
    
    # ***** Primitives ***** #
    
    def primitive_include(mod)
      self.super = IncludeClassInstance.new(runtime, mod, self.super)
      
      # If the module being included has some primitives, then make them available by including
      # the actual primitive methods in the instance class, and adding them to the method table
      if mod.primitives_module
        instance_class.send(:include, mod.primitives_module)
        method_table.merge!(mod.primitives_module.primitives)
      end
      
      mod
    end
    
    alias_method :primitive_ancestors, :ancestors
    
    def primitive_inspect
      name.to_s
    end
  end
end
