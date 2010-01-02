module Carat::AST
  class True < Node
  end
  
  class False < Node
  end
  
  class Nil < Node
  end
  
  class String < ValueNode
  end
  
  class Integer < ValueNode
    def eval
      constants[:Fixnum].get(value)
    end
  end
  
  class Array < NodeList
  end
end
