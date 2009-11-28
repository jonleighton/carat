class Carat::Runtime
  class Stack
    attr_reader :runtime, :frames
  
    def initialize(runtime)
      @runtime = runtime
      @frames = []
    end
    
    # Create a frame from an expression and push it on to the stack. Either use the given scope or
    # the top-level scope provided by the runtime.
    def push(sexp, scope = nil)
      @frames << Frame.new(self, sexp, scope || runtime.scope)
      peek
    end
    
    # Execute the frame at the top of the stack, then pop it and return the result
    def reduce
      result = peek.eval
      pop
      result
    end
    
    # Push a sexp with an optional scope on to the stack and reduce immediately
    def execute(sexp, scope = nil)
      push(sexp, scope)
      reduce
    end
    
    # Get the last stack frame
    def peek
      @frames.last
    end
    
    # Remove and return the last stack frame
    def pop
      @frames.pop
    end
  end
end
