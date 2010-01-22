module Carat::AST
  class True < ValueNode
    def value_object
      runtime.true
    end
  end
  
  class False < ValueNode
    def value_object
      runtime.false
    end
  end
  
  class Nil < ValueNode
    def value_object
      runtime.nil
    end
  end
  
  class String < MultipleValueNode
    def value_object
      Carat::Data::StringInstance.new(runtime, value)
    end
  end
  
  class Integer < MultipleValueNode
    def value_object
      constants[:Fixnum].get(value)
    end
  end
  
  class Array < NodeList
    def eval(&continuation)
      append = lambda do |object, accumulation, node|
        accumulation << object
      end
      
      eval_fold([], append) do |item_objects|
        constants[:Array].new(item_objects, &continuation)
      end
    end
  end
end
