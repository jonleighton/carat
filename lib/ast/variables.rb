module Carat::AST
  class Assignment < Node
    attr_reader :variable, :value
    
    def initialize(variable, value)
      @variable, @value = variable, value
    end
    
    def eval
      variable.scope = scope
      variable.assign(execute(value))
    end
    
    def inspect
      type + ": " + variable.inspect + " = \n" + indent(value.inspect)
    end
  end
  
  class LocalVariable < NamedNode
    def assign(value)
      scope[name] = value
    end
  end
  
  class LocalVariableOrMethodCall < NamedNode
    def eval
      if scope.has?(name)
        scope[name]
      else
        scope[:self].call(name)
      end
    end
  end
  
  class InstanceVariable < NamedNode
    def object
      scope[:self]
    end
  
    def assign(value)
      object.instance_variables[name] = value
    end
    
    def eval
      object.instance_variables[name] || constants[:NilClass].instance
    end
  end
  
  class Constant < NamedNode
    def eval
      constants[name]
    end
  end
end
