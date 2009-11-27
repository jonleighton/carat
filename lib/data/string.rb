module Carat::Data
  class StringClass < ClassInstance
  end
  
  class StringInstance < ObjectInstance
    def initialize(runtime, contents)
      @contents = contents
      super(runtime, runtime.constants[:String])
    end
    
    def to_s
      @contents
    end
    
    def primitive_to_s
      self
    end
  end
end
