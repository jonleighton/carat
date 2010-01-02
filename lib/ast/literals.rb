module Carat::AST
  class True < Node
    def eval
      constants[:TrueClass].instance
    end
  end
  
  class False < Node
    def eval
      constants[:FalseClass].instance
    end
  end
  
  class Nil < Node
    def eval
      constants[:NilClass].instance
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
