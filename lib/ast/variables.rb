module Carat::AST
  class Assignment < Node
    attr_reader :variable, :value
    
    def initialize(variable, value)
      @variable, @value = variable, value
    end
    
    def children
      [variable, value]
    end
    
    def eval
      eval_child(value) do |value_object|
        yield variable.assign(value_object)
      end
    end
    
    def inspect
      type + ": " + variable.inspect + " = \n" + indent(value.inspect)
    end
  end
  
  class LocalVariable < NamedNode
    def assign(value)
      current_scope[name] = value
    end
  end
  
  class LocalVariableOrMethodCall < NamedNode
    def eval(&continuation)
      if current_scope[name]
        yield current_scope[name]
      elsif current_object.has_instance_method?(name)
        current_object.call(name, &continuation)
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
      yield(current_object.instance_variables[name] || runtime.nil)
    end
  end
  
  class Constant < NamedNode
    def eval
      yield constants[name]
    end
  end
end
