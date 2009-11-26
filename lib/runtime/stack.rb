class Carat::Runtime
  class Stack < Array
    # Push a frame on to the stack. Assign this stack to the frame so it has a reference.
    def <<(frame)
      frame.stack = self
      super
    end
    
    # Execute the frame at the top of the stack, then pop it and return the result
    def reduce
      result = peek.execute
      pop
      result
    end
    
    # Push a frame on the stack and execute it right away
    def execute(frame)
      self << frame
      reduce
    end
    
    alias_method :peek, :last
  end
end
