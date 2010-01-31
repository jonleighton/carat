module Carat::AST
  class Assignment < Node
    child :variable
    child :value
    
    def eval
      eval_child(value) do |value_object|
        yield variable.assign(value_object)
      end
    end
  end
  
  class LocalVariable < NamedNode
    def assign(value)
      current_scope[name] = value
    end
    
    def eval(&continuation)
      if current_scope[name]
        yield current_scope[name]
      else
        raise Carat::CaratError, "undefined local variable '#{name}'"
      end
    end
  end
  
  class LocalVariableOrMethodCall < NamedNode
    def eval(&continuation)
      if current_scope[name]
        yield current_scope[name]
      else
        current_object.call(name, [], location, :NameError, &continuation)
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
      if constants[name]
        yield constants[name]
      else
        raise Carat::CaratError, "constant '#{name}' not found"
      end
    end
  end
end
