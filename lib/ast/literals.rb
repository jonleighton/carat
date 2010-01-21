module Carat::AST
  class True < Node
    def eval
      yield runtime.true
    end
  end
  
  class False < Node
    def eval
      yield runtime.false
    end
  end
  
  class Nil < Node
    def eval
      yield runtime.nil
    end
  end
  
  class String < ValueNode
    def eval
      yield Carat::Data::StringInstance.new(runtime, value)
    end
  end
  
  class Integer < ValueNode
    def eval
      yield constants[:Fixnum].get(value)
    end
  end
  
  class Array < NodeList
    def eval
      eval_array(items) do |item_objects|
        yield constants[:Array].new(item_objects)
      end
    end
  end
end
