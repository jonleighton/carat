module Carat::AST
  class IfExpression < Node
    attr_reader :condition, :true_node, :false_node
    
    def initialize(condition, true_node, false_node)
      @condition, @true_node, @false_node = condition, true_node, false_node
    end
    
    def children
      [condition, true_node, false_node]
    end
    
    def eval(&continuation)
      eval_child(condition) do |condition_value|
        if condition_value.false_or_nil?
          eval_child(true_node, &continuation)
        else
          eval_child(false_node, &continuation)
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
