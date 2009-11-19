module Carat::Runtime::Bootstrap
  module Fixnum
    module SingletonExtensions
      def instances
        @instances = {}
      end
      
      def get(number)
        if instances[number]
          instances[number]
        else
          instance = primitive_new
          instance.value = number
          instances[number] = instance
        end
      end
    end
    
    module Extensions
      attr_accessor :value
      
      def to_s
        value && value.to_s || super
      end
    end
    
    module Primitives
      def +(other)
        klass.get(value + other.value)
      end
      
      def -(other)
        klass.get(value - other.value)
      end
      
      def to_s
        value.to_s
      end
    end
  end
end
