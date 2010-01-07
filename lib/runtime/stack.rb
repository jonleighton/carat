class Carat::Runtime
  class Stack
    def initialize
      @items = []
    end
    
    # Return each item in turn
    def each_item(&block)
      @items.each(&block)
    end
    
    # Add an item to the top of the stack
    def <<(item)
      @items << item
    end
    
    # Get the item at the top of the stack
    def peek
      @items.last
    end
    
    # Remove and return the item at the top of the stack
    def pop
      @items.pop
    end
    
    # Get the height of the stack
    def height
      @items.length
    end
    
    # Get an item at a certain stack depth. '0' is the top of the stack, '1' is second, etc.
    def [](index)
      @items[height - index - 1]
    end
    
    # "Reduce" the stack in some way
    def reduce
      raise NotImplementedError
    end
    
    # Push an item on to the stack and reduce immediately
    def execute(item)
      self << item
      reduce
    end
    
    # Print out the stack
    def inspect
      result = []
      @items.each_with_index do |item, i|
        result << " #{height - i}. #{item.inspect.gsub("\n", "\n    ")}"
      end
      result.join("\n")
    end
  end
  
  class ExecutionStack < Stack
    attr_reader :runtime
  
    def initialize(runtime)
      @runtime = runtime
      super()
    end
    
    # Execute the node at the top of the stack, then pop it and return the result
    def reduce
      result = peek.eval_in_runtime(runtime)
      pop
      result
    end
  end
  
  class CallStack < Stack
    # Send the call at the top of the stack, and then remove it
    def reduce
      result = peek.send
      pop
      result
    end
  end
end
