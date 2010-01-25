module Carat::Data
  class FixnumClass < ClassInstance
    def instances
      @instances ||= {}
    end
    
    def get(number)
      instances[number] ||= FixnumInstance.new(runtime, number)
    end
  end
  
  class FixnumInstance < ObjectInstance
    attr_reader :value
    
    def initialize(runtime, value)
      @value = value
      super(runtime, runtime.constants[:Fixnum])
    end
    
    def to_s
      value && value.to_s || super
    end
    
    # ***** Primitives ***** #
    
    def primitive_plus(other)
      yield klass.get(value + other.value)
    end
    
    def primitive_minus(other)
      yield klass.get(value - other.value)
    end
    
    def primitive_to_s
      yield constants[:String].new(value.to_s)
    end
  end
end
