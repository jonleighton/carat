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
      add_primitives_to_method_table if runtime.initialized?
    end
    
    # Modules have a metaclass so that they can have module methods. The class of the metaclass is
    # always +Module+.
    def get_klass(runtime)
      MetaClassInstance.new(runtime, self, runtime.constants[:Module])
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
    
    def to_s
      "<module:#{name}>"
    end
    
    def primitive_include(mod)
      self.super = IncludeClassInstance.new(runtime, mod, self.super)
    end
    
    alias_method :primitive_ancestors, :ancestors
    
    def primitive_inspect
      name.to_s
    end
  end
end
