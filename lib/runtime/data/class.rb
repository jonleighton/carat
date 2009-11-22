class Carat::Runtime
  class ClassClass < ClassInstance
  end

  class ClassInstance < ModuleInstance
    def initialize(runtime, supr, name = nil)
      self.super = supr
      super(runtime, name || inferred_name)
      add_primitives_to_method_table if runtime.initialized?
    end
    
    # For a standard +Class+ (as opposed to a +SingletonClass+), we create a metaclass
    # and use that "The superclass of the metaclass is the metaclass of the superclass" :)
    def get_klass(runtime)
      MetaClassInstance.new(runtime, self, superclass && superclass.metaclass)
    end
    
    # The inferred name is the name of the class in the object language, taken from the name of the
    # class representing it in the metalanguage. For instance, if this is an instance of
    # +FixnumClass+, then the inferred name is +:Fixnum+
    def inferred_name
      @inferred_name ||= begin
        # We must be in a subclass of ClassInstance in order to infer a name
        unless instance_of?(ClassInstance)
          self.class.to_s.sub(/^.*\:\:/, '').sub(/Class$/, '').to_sym
        end
      end
    end
    
    def instance_class_name
      "#{name}Instance"
    end
    
    # Returns the class which is used to represent an instance of this class.
    # 
    # For example, if this class is +FixnumClass+, the +instance_class+ will be +FixnumInstance+
    def instance_class
      @instance_class ||= begin
        if Carat::Runtime.const_defined?(instance_class_name)
          Carat::Runtime.const_get(instance_class_name)
        else
          Carat::Runtime::ObjectInstance
        end
      end
    end
    
    def add_primitives_to_method_table
      method_table.merge!(instance_class.primitives)
    end
    
    # The super may be an include class for a module, but we want the first ancestor which is a 
    # "proper" class
    def superclass
      if self.super.is_a?(IncludeClassInstance)
        self.super && self.super.superclass
      else
        self.super
      end
    end
    
    def superclass=(klass)
      raise Carat::CaratError, "You can't set a non-class as the superclass" unless klass.is_a?(ClassInstance)
      self.super = klass
    end
    
    def to_s
      "<class:#{name}>"
    end
    
    # ***** Primitives ***** #
    
    def primitive_new(*args)
      object = instance_class.new(runtime, self)
      object.call(:initialize, args)
      object
    end
    
    def primitive_include(mod)
      super
      
      # If the module being included has some primitives, then make them available by including
      # the actual primitive methods in the instance class, and adding them to the method table
      if mod.primitives_module
        instance_class.send(:include, mod.primitives_module)
        method_table.merge!(mod.primitives_module.primitives)
      end
      
      mod
    end
  end
end
