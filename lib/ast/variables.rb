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
      scope[name] || call_or_error
    end
    
    def call_or_error
      if current_object.has_instance_method?(name)
        current_object.call(name)
      else
        raise Carat::CaratError, "undefined local variable or method '#{name}'"
      end
    end
  end
  
  class InstanceVariable < NamedNode
    def assign(value)
      current_object.instance_variables[name] = value
    end
    
    def eval
      current_object.instance_variables[name] || constants[:NilClass].instance
    end
  end
  
  class Constant < NamedNode
    def eval
      constants[name]
    end
  end
end
