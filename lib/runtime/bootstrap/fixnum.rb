module Carat::Runtime::Bootstrap
  module Fixnum
    module ClassExtensions
      def instances
        @instances = {}
      end
      
      def get(number)
        if instances[number]
          instances[number]
        else
          instance = runtime.new_instance(self)
          instance.value = number
          instances[number] = instance
        end
      end
    end
    
    module ObjectExtensions
      attr_accessor :value
      
      def to_s
        @value.to_s
      end
    end
    
    module ObjectPrimitives
      def +(other)
        runtime.constants[:Fixnum].get(@value + other.value)
      end
      
      def -(other)
        runtime.constants[:Fixnum].get(@value - other.value)
      end
      
      def to_s
        @value.to_s
      end
    end
  end
end
