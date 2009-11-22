module Carat::Data
  class IncludeClassInstance < ClassInstance
    attr_reader :module
    
    extend Forwardable
    def_delegators :"self.module", :primitives_module, :extensions_module,
                                   :lookup_instance_method, :name
    
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
    
    def to_s
      "<include_class:#{klass}>"
    end
  end
end
