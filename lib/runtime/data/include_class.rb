class Carat::Runtime
  class IncludeClass < Class
    attr_reader :module
    
    def initialize(runtime, mod, supr)
      @module = mod
      super(runtime, supr)
      
      # An include class does not have its own method table, it uses the method table of the module
      # being included
      self.methods = mod.methods
    end
    
    def get_klass(runtime)
      self.module
    end
    
    def to_s
      "<include_class:#{klass}>"
    end
  end
end
