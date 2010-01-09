module Carat::AST
  class IfExpression < Node
    attr_reader :condition, :true_node, :false_node
    
    def initialize(condition, true_node, false_node)
      @condition, @true_node, @false_node = condition, true_node, false_node
    end
    
    def condition?
      result = execute(condition)
      result != runtime.false && result != runtime.nil
    end
    
    def eval
      if condition?
        execute(true_node)
      else
        execute(false_node)
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
