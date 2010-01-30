module Carat::AST
  class If < Node
    attr_reader :condition, :true_node, :false_node
    
    def initialize(location, condition, true_node, false_node)
      super(location)
      @condition, @true_node, @false_node = condition, true_node, false_node
    end
    
    def children
      [condition, true_node, false_node]
    end
    
    def eval(&continuation)
      eval_child(condition) do |condition_value|
        if condition_value.false_or_nil?
          eval_child(false_node, &continuation)
        else
          eval_child(true_node, &continuation)
        end
      end
    end
    
    def inspect
      type + ":\n" +
        "Condition:\n" + indent(condition.inspect) + "\n" +
        "True Branch:\n" + indent(true_node.inspect) + "\n" +
        "False Branch:\n" + indent(false_node.inspect)
    end
  end
  
  class While < Node
    attr_reader :condition, :contents
    
    def initialize(location, condition, contents)
      super(location)
      @condition, @contents = condition, contents
    end
    
    def children
      [condition, contents]
    end
    
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
    
    def inspect
      type + ":\n" +
        "Condition:\n" + indent(condition.inspect) + "\n" +
        "Contents:\n" + indent(contents.inspect)
    end
  end
  
  class Begin < Node
    attr_reader :contents, :rescue
    
    def initialize(contents, rescu)
      @contents, @rescue = contents, rescu
    end
    
    def children
      [contents, self.rescue]
    end
    
    def eval(&continuation)
      self.rescue.setup(continuation)
      eval_child(contents, &continuation)
    end
    
    def inspect
      type + ":\n" +
        "Contents:\n" + indent(contents.inspect) + "\n" +
        "Rescue:\n" + indent(self.rescue.inspect)
    end
  end
  
  class Rescue < Node
    attr_reader :error_type, :exception_variable, :contents
    
    def initialize(error_type, exception_variable, contents)
      @error_type, @exception_variable, @contents = error_type, exception_variable, contents
    end
    
    def children
      [error_type, exception_variable, contents]
    end
    
    def eval_error_type(&continuation)
      if error_type
        eval_child(error_type, &continuation)
      else
        yield constants[:RuntimeError]
      end
    end
    
    def setup(return_continuation)
      previous_failure_continuation = runtime.failure_continuation
      runtime.failure_continuation = lambda do |exception|
        runtime.failure_continuation = previous_failure_continuation
        
        eval_error_type do |error_type_object|
          exception.call(:is_a?, [error_type_object]) do |exception_match|
            if exception_match == runtime.true
              exception_variable.assign(exception) unless exception_variable.nil?
              eval_child(contents, &return_continuation)
            else
              previous_failure_continuation.call(exception)
            end
          end
        end
      end
    end
    
    def inspect
      type + ":\n" +
        "Error type:\n" + indent(error_type.inspect) + "\n" +
        "Assignment:\n" + indent(assignment.inspect) + "\n" +
        "Contents:\n" + indent(contents.inspect)
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
