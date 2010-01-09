module Carat::AST
  class True < Node
    def eval
      runtime.true
    end
  end
  
  class False < Node
    def eval
      runtime.false
    end
  end
  
  class Nil < Node
    def eval
      runtime.nil
    end
  end
  
  class String < ValueNode
    def eval
      Carat::Data::StringInstance.new(runtime, value)
    end
  end
  
  class Integer < ValueNode
    def eval
      constants[:Fixnum].get(value)
    end
  end
  
  class Array < NodeList
    def item_objects
      items.map { |item| execute(item) }
    end
    
    def eval
      constants[:Array].call(:new, item_objects)
    end
  end
end
