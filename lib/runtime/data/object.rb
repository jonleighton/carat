class Carat::Runtime
  class Object
    attr_reader :runtime
    attr_accessor :klass
    
    extend Forwardable
    def_delegator :klass, :bootstrap_module
    
    class << self
      def demodulized_name
        to_s.split("::").last
      end
    end
    
    def initialize(runtime, klass)
      raise Carat::CaratError, "cannot create object without a class" if klass.nil?
      @runtime, @klass = runtime, klass
      
      include_extensions(extensions_module) if extensions_module
      include_primitives(primitives_module) if primitives_module
    end
    
    def extensions_module
      if bootstrap_module && bootstrap_module.const_defined?("#{self.class.demodulized_name}Extensions")
        bootstrap_module.const_get("#{self.class.demodulized_name}Extensions")
      end
    end
    
    def primitives_module
      if bootstrap_module && bootstrap_module.const_defined?("#{self.class.demodulized_name}Primitives")
        bootstrap_module.const_get("#{self.class.demodulized_name}Primitives")
      end
    end
    
    def include_extensions(mod)
      (class << self; self; end).send(:include, mod)
    end
    
    def include_primitives(mod)
      mod.instance_methods.each do |method_name|
        klass.methods[method_name.sub(/^primitive_/, '').to_sym] = Primitive.new(method_name.to_sym)
      end
      
      (class << self; self; end).send(:include, mod)
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
      "<Carat::Runtime::Object:(#{object_id}) " +
      "@klass=#{real_klass} " + 
      "@instance_variables=#{instance_variables.inspect}>"
    end
  end
end
