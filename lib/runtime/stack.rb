class Carat::Runtime
  class Stack < Array
    # Accept a frame onto the stack, evaluate it, then remove it and return its result
    def <<(frame)
      super(frame)
      result = frame.eval(self)
      pop
      result
    end
    
    alias_method :peek, :last
  end
end
