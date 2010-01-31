module Carat::Data
  class StringClass < ClassInstance
    def new(contents = "")
      StringInstance.new(runtime, self, contents.to_s)
    end
  
    def primitive_allocate
      yield new
    end
  end
  
  class StringInstance < ObjectInstance
    attr_reader :contents
  
    def initialize(runtime, klass, contents = "")
      @contents = contents
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
      yield real_klass.new(contents << other.contents)
    end
  end
end
