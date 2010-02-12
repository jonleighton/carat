module Carat::AST
  class If < Node
    child :condition
    child :true_node
    child :false_node
    
    def eval(&continuation)
      eval_child(condition) do |condition_value|
        if condition_value.false_or_nil?
          eval_child(false_node, &continuation)
        else
          eval_child(true_node, &continuation)
        end
      end
    end
  end
  
  class While < Node
    child :condition
    child :contents
    
    def eval(&continuation)
      loop = lambda do
        eval_child(condition) do |condition_value|
          if condition_value.false_or_nil?
            yield runtime.nil
          else
            eval_child(contents) do |contents_value|
              loop.call
            end
          end
        end
      end
      
      loop.call
    end
  end
  
  class Begin < Node
    child :contents
    child :rescue
    
    def eval(&continuation)
      self.rescue.setup(&continuation)
      eval_child(contents) do |result|
        self.rescue.teardown
        yield result
      end
    end
  end
  
  class Rescue < Node
    child :error_type
    child :exception_variable
    child :contents
    
    def eval_error_type(&continuation)
      if error_type
        eval_child(error_type, &continuation)
      else
        yield constants[:RuntimeError]
      end
    end
    
    def failure_continuation(&continuation)
      scope_stack_length = scope_stack.length
      call_stack_length = call_stack.length
      
      lambda do |exception, location|
        # Remove this failure continuation from the stack
        failure_continuation_stack.pop
        
        # If this failure continuation matches the error, evaluate its contents. Otherwise, call
        # the failure continuation which is now at the top of the stack
        eval_error_type do |error_type_object|
          exception.call(:is_a?, [error_type_object]) do |exception_match|
            if exception_match == runtime.true
              # Remove the parts of the scope stack and call stack between here and where the exception
              # was raised
              scope_stack.slice!(scope_stack_length..-1)
              call_stack.slice!(call_stack_length..-1)
              
              # Assign the exception to the given variable
              exception_variable.assign(exception) unless exception_variable.nil?
              
              eval_child(contents, &continuation)
            else
              current_failure_continuation.call(exception, location)
            end
          end
        end
      end
    end
    
    def setup(&continuation)
      failure_continuation_stack << failure_continuation(&continuation)
    end
    
    def teardown
      failure_continuation_stack.pop
    end
  end
  
  class And < BinaryNode
    def eval(&continuation)
      eval_child(left) do |left_value|
        if left_value.false_or_nil?
          yield left_value
        else
          eval_child(right, &continuation)
        end
      end
    end
  end
  
  class Or < BinaryNode
    def eval(&continuation)
      eval_child(left) do |left_value|
        if left_value.false_or_nil?
          eval_child(right, &continuation)
        else
          yield left_value
        end
      end
    end
  end
end
