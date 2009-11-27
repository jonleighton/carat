module Carat::Data
  class StringClass < ClassInstance
    def primitive_allocate
      StringInstance.new(runtime, "")
    end
  end
  
  class StringInstance < ObjectInstance
    attr_reader :contents
  
    def initialize(runtime, contents)
      @contents = contents
      super(runtime, runtime.constants[:String])
    end
    
    def to_s
      contents
    end
    
    # ***** PRIMITIVES ***** #
    
    def primitive_to_s
      self
    end
    
    def primitive_inspect
      contents.inspect
    end
    
    def primitive_plus(other)
      to_s + other.to_s
    end
    rename_primitive :plus, :+
  end
end
