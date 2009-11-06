class Carat::Runtime
  class Object
    attr_reader :runtime
    attr_accessor :klass
    
    def initialize(runtime, klass)
      # Check that the class of the object is actually given. If the runtime is still initializing
      # we omit this check, as there are circular references which need to be set up.
      if runtime.initialized? && klass.nil?
        raise Carat::CaratError, "cannot create object without a class"
      end
      
      @runtime, @klass = runtime, klass
      
      if @klass && @klass.object_extension
        (class << self; self; end).send(:include, @klass.object_extension)
      end
    end
    
    def instance_variables
      @instance_variables ||= {}
    end
    
    def lookup_method(name, raise_on_failure = true)
      method = klass.methods[name] || raise(Carat::CaratError, "method '#{self}##{name}' not found")
    end
    
    def method_defined?(name)
      !klass.methods[name].nil?
    end
    
    # If the class is already a singleton class then return it, otherwise create one and insert it
    # in the hierarchy in between this object and the class. Note: +Class+ creates its singleton
    # class on initialization, and the way it fits into the hierarchy is slightly different.
    def singleton_class
      if klass.is_a?(SingletonClass)
        klass
      else
        self.klass = SingletonClass.new(runtime, klass)
      end
    end
    
    def real_klass
      klass.is_a?(SingletonClass) ? klass && klass.real_klass : klass
    end
    
    def to_s
      "<object:#{klass}>"
    end
    
    def inspect
      "<Carat::Runtime::Object @klass=#{real_klass} @instance_variables=#{instance_variables.inspect}>"
    end
  end
end
