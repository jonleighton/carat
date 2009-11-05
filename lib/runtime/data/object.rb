class Carat::Runtime
  class Object
    attr_reader :instance_variables
    attr_accessor :klass
    
    def initialize(klass)
      @klass = klass
      @instance_variables = {}
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
  end
end
