class Carat::Runtime
  class Object
    attr_reader :klass, :instance_variables
    
    def initialize(klass)
      @klass = klass
      @instance_variables = {}
    end
    
    def lookup_method(method_name)
      klass.methods[method_name]
    end
    
    def to_s
      "<object:#{klass}>"
    end
  end
end
