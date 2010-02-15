module Carat::Data
  class StringClass < ClassInstance
    def new(contents = "")
      StringInstance.new(runtime, self, contents)
    end
  
    def primitive_allocate
      yield new
    end
  end
  
  class StringInstance < ObjectInstance
    attr_reader :contents
  
    def initialize(runtime, klass, contents = "")
      # clone the contents string because it is important to make sure that two separate 
      # StringInstances aren't stored by the same underlying String object
      @contents = contents.to_s.clone
      super(runtime, klass)
    end
    
    def to_s
      contents
    end
    
    # ***** Primitives ***** #
    
    def primitive_inspect
      yield real_klass.new(contents.inspect)
    end
    
    def primitive_plus(other)
      other.call(:to_s) do |other_as_string|
        yield real_klass.new(contents + other_as_string.contents)
      end
    end
    
    def primitive_push(other)
      contents << other.contents
      yield self
    end
    
    def primitive_equal_to(other)
      if contents == other.contents
        yield runtime.true
      else
        yield runtime.false
      end
    end
  end
end
