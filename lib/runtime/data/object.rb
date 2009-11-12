class Carat::Runtime
  class Object
    attr_reader :runtime
    attr_accessor :klass
    
    def initialize(runtime, klass)
      if klass.nil? && runtime.initialized?
        raise Carat::CaratError, "cannot create object without a class"
      end
      
      @runtime, @klass = runtime, klass
      include_bootstrap_modules if runtime.initialized?
    end
    
    # Lookup a instance method - i.e. one defined by this object's class
    def lookup_instance_method(name)
      klass.lookup_method(name) || raise(Carat::CaratError, "method '#{self}##{name}' not found")
    end
    
    # Include some behaviour just for this specific instance
    def singleton_include(*modules)
      modules.each do |mod|
        (class << self; self; end).send(:include, mod)
      end
    end
    
    def include_bootstrap_modules
      # Include extensions defined for this instances of the class
      singleton_include(klass.extensions_module) if klass.extensions_module
      
      # Include the object primitives from the class
      singleton_include(*klass.primitives)
    end
    
    def instance_variables
      @instance_variables ||= {}
    end
    
    # If the class is already a singleton class then return it, otherwise create one and insert it
    # in the hierarchy in between this object and the class. Note: +Class+ creates its singleton
    # class on initialization, and the way it fits into the hierarchy is slightly different.
    def singleton_class
      if klass.is_a?(SingletonClass)
        klass
      else
        self.klass = SingletonClass.new(runtime, self, klass)
      end
    end
    
    def real_klass
      klass.is_a?(SingletonClass) ? klass && klass.real_klass : klass
    end
    
    def to_s
      "<object:#{klass}>"
    end
    
    def inspect
      "<#{self.class}:(#{object_id}) " +
      ":klass=#{real_klass} " + 
      ":instance_variables=#{instance_variables.inspect} " +
      ":to_s=#{to_s}>"
    end
  end
end
