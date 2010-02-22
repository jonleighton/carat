module Carat::AST
  class Assignment < Node
    child :receiver
    child :value
    
    def eval(&continuation)
      eval_child(value) do |value_object|
        receiver.assign(value_object, &continuation)
      end
    end
  end
  
  class LocalVariable < NamedNode
    def assign(value)
      yield current_scope[name] = value
    end
    
    # The only time when a local variable is explicitly distinguished from a method call is when we
    # have a line such as "foo ||= 42". In this case, the LHS is taken to be a local variable (not
    # a method call), and the expression is expanded into an AST node representing "foo = foo || 42",
    # but the occurance of "foo" on the RHS is also assumed to be a local variable.
    def eval(&continuation)
      if current_scope[name]
        yield current_scope[name]
      else
        runtime.raise :NameError, "undefined local variable '#{name}'"
      end
    end
  end
  
  class LocalVariableOrMethodCall < NamedNode
    def eval(&continuation)
      if current_scope[name]
        yield current_scope[name]
      elsif current_object.has_instance_method?(name)
        current_object.call(name, [], location, &continuation)
      else
        runtime.raise :NameError, "undefined local variable or method '#{name}'"
      end
    end
  end
  
  class InstanceVariable < NamedNode
    def assign(value)
      yield current_object.instance_variables[name] = value
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
        runtime.raise :NameError, "undefined constant '#{name}'"
      end
    end
  end
end
