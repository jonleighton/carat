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
  end
end
