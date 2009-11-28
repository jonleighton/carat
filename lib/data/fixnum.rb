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
    
    def primitive_plus(other)
      value + other.value
    end
    rename_primitive :plus, :+
    
    def primitive_minus(other)
      value - other.value
    end
    rename_primitive :minus, :-
    
    def primitive_to_s
      value.to_s
    end
  end
end
