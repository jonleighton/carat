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
      failure_continuation = self.rescue.failure_continuation(&continuation) if self.rescue
      eval_child(contents, failure_continuation, &continuation)
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
    
    def check_error_type(exception, &continuation)
      eval_error_type do |error_type_object|
        exception.call(:is_a?, [error_type_object]) do |exception_match|
          yield exception_match == runtime.true
        end
      end
    end
    
    def failure_continuation(&continuation)
      lambda do |exception|
        # Remove the frame for this failure continuation from the stack
        stack.pop
        
        # If this failure continuation matches the error, evaluate its contents. Otherwise, unwind
        # the stack to the frame of the next failure continuation, and call that.
        check_error_type(exception) do |error_type_matches|
          if error_type_matches
            exception_variable.assign(exception) unless exception_variable.nil?
            eval_child(contents, &continuation)
          else
            stack.unwind_to(:failure_continuation)
            current_failure_continuation.call(exception)
          end
        end
      end
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
