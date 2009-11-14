class Carat::Runtime
  class Module < Object
    attr_reader :name
    attr_accessor :super
    attr_writer :methods
    
    def initialize(runtime, name = nil)
      @name = name
      super(runtime, get_klass(runtime))
    end
    
    # The class of the module is +Module+
    def get_klass(runtime)
      runtime.constants[:Module]
    end
    
    # The methods available to instances
    def methods
      @methods ||= {}
    end
    
    def lookup_method(name)
      methods[name] || (self.super && self.super.lookup_method(name))
    end
    
    def to_s
      "<module:#{name}>"
    end
  end
end
