class Carat::Runtime
  class FixnumClass < ClassInstance
    def instances
      @instances = {}
    end
    
    def get(number)
      if instances[number]
        instances[number]
      else
        instance = call(:new)
        instance.value = number
        instances[number] = instance
      end
    end
  end
  
  class FixnumInstance < ObjectInstance
    attr_accessor :value
    
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
