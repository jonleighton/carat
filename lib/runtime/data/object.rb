class Carat::Runtime
  class Object
    attr_reader :runtime, :instance_variables
    attr_accessor :klass
    
    def initialize(runtime, klass)
      @runtime, @klass = runtime, klass
      @instance_variables = {}
      
      if @klass && @klass.object_extension
        (class << self; self; end).send(:include, @klass.object_extension)
      end
    end
    
    def lookup_method(name, raise_on_failure = true)
      method = klass.methods[name] || raise(Carat::CaratError, "method '#{self}##{name}' not found")
    end
    
    def method_defined?(name)
      !klass.methods[name].nil?
    end
    
    def to_s
      "<object:#{klass}>"
    end
    
    def inspect
      "<Carat::Runtime::Object @klass=#{klass.name} @instance_variables=#{@instance_variables.inspect}>"
    end
  end
end
