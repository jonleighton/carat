class Carat::Runtime
  class IncludeClassInstance < ClassInstance
    attr_reader :module
    
    extend Forwardable
    def_delegators :"self.module", :primitives_module, :extensions_module
    
    def initialize(runtime, mod, supr)
      @module = mod
      super(runtime, supr)
      
      # An include class does not have its own method table, it uses the method table of the module
      # being included
      self.method_table = mod.method_table
    end
    
    def get_klass(runtime)
      self.module
    end
    
    # Delegate primitive_ methods to the module
    def method_missing(name, *args)
      if name.to_s =~ /^primitive_/
        self.module.send(name, *args)
      else
        raise NoMethodError, "undefined method `#{name}' for #{self.inspect}"
      end
    end
    
    def to_s
      "<include_class:#{klass}>"
    end
  end
end
