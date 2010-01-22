module Carat::AST
  class IfExpression < Node
    attr_reader :condition, :true_node, :false_node
    
    def initialize(condition, true_node, false_node)
      @condition, @true_node, @false_node = condition, true_node, false_node
    end
    
    def children
      [condition, true_node, false_node]
    end
    
    def eval_condition
      eval_child(condition) do |condition_value|
        yield condition_value != runtime.false &&
              condition_value != runtime.nil
      end
    end
    
    def eval(&continuation)
      eval_condition do |value|
        if value
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
end
