module Carat::Data
  class StringClass < ClassInstance
    def new(contents)
      StringInstance.new(runtime, contents)
    end
  
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
    
    def primitive_inspect
      real_klass.new(contents.inspect)
    end
    
    def primitive_plus(other)
      real_klass.new(contents + other.call(:to_s).contents)
    end
    
    def primitive_push(other)
      real_klass.new(contents << other.contents)
    end
  end
end
