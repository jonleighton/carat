# Evaluates an AST node within the given scope. This file sets up some helper methods, and
# +frame_evaluation.rb+ contains all the evaluation logic.
class Carat::Runtime
  class Frame
    attr_reader :stack, :node, :scope
    
    extend Forwardable
    def_delegators :stack, :runtime
    def_delegators :runtime, :constants
    
    def initialize(stack, node, scope)
      @stack, @node, @scope = stack, node, scope
    end
    
    # Evaluate this frame
    def eval
      return nil if node.nil?
      
      if respond_to?("eval_#{node.type}")
        send("eval_#{node.type}", node)
      else
        raise Carat::CaratError, "'#{node.type}' not implemented"
      end
    end
    
    # Execute a node on the stack. Either use the given scope, or the current scope otherwise.
    def execute(node_or_object, scope = nil)
      if node_or_object.is_a?(Carat::Data::ObjectInstance)
        node_or_object # We have an immediate value, no need to evaluate it
      else
        stack.execute(node_or_object, scope || self.scope)
      end
    end
    
    require Carat::RUNTIME_PATH + "/frame_evaluation"
  end
end
