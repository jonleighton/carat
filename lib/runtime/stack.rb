class Carat::Runtime
  class Stack
    attr_reader :runtime, :nodes
  
    def initialize(runtime)
      @runtime = runtime
      @nodes = []
    end
    
    def <<(node)
      @nodes << node
    end
    
    # Execute the frame at the top of the stack, then pop it and return the result
    def reduce
      result = peek.eval_in_runtime(runtime)
      pop
      result
    end
    
    # Push a node on to the stack and reduce immediately
    def execute(node)
      self << node
      reduce
    end
    
    # Get the last stack frame
    def peek
      @nodes.last
    end
    
    # Remove and return the last stack frame
    def pop
      @nodes.pop
    end
  end
end
