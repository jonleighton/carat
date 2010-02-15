class Carat::Runtime
  # A stack frame can contain a scope, a call, and a failure continuation. All are optional, but it
  # is expected that a frame will contain at least one of these (otherwise it is pretty useless).
  class Frame
    attr_reader :scope, :call, :failure_continuation
    
    def initialize(scope = nil, call = nil, failure_continuation = nil)
      @scope, @call, @failure_continuation = scope, call, failure_continuation
    end
  end
  
  # The stack contains a number of stack frames. It has a current scope, current call and current
  # failure continuation, which is taken from the frame nearest the top of the stack which has
  # the desired attribute.
  class Stack
    def initialize
      @items = []
    end
    
    def <<(item)
      @items << item
      invalidate_cache
      self
    end
    
    def current_scope
      @current_scope ||= find_last(:scope)
    end
    
    def current_call
      @current_call ||= find_last(:call)
    end
    
    def current_failure_continuation
      @current_failure_continuation ||= find_last(:failure_continuation)
    end
    
    def pop
      item = @items.pop
      invalidate_cache
      item
    end
    
    # Pop frames from the stack until we get to the first frame with the given attribute
    def unwind_to(attribute)
      frame = @items.last
      while frame.send(attribute).nil?
        @items.pop
        frame = @items.last
      end
      invalidate_cache
      frame
    end
    
    def to_a
      @items.clone
    end
    
    private
    
      def invalidate_cache
        @current_scope = nil
        @current_call = nil
        @current_failure_continuation = nil
      end
      
      # Find the frame nearest to the top of the stack where the given attribute is non-nil
      def find_last(attribute)
        i = @items.length - 1
        i -= 1 while i >= 0 && @items[i].send(attribute).nil?
        @items[i].send(attribute) if i >= 0
      end
  end
end
