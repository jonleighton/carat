module Carat::AST
  class Assignment < Node
    attr_reader :variable, :value
    
    def initialize(variable, value)
      @variable, @value = variable, value
    end
    
    def inspect
      type + ": " + variable.inspect + " = \n" + indent(value.inspect)
    end
  end
  
  class LocalVariable < NamedNode
  end
  
  class LocalVariableOrMethodCall < NamedNode
  end
  
  class InstanceVariable < NamedNode
  end
  
  class Constant < NamedNode
    def eval
      constants[name]
    end
  end
end
