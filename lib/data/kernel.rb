module Carat::Data
  module KernelModule
    def primitive_puts(object)
      if object == runtime.nil
        Kernel.puts("nil")
        yield runtime.nil
      else
        # object.call(:to_s) gets the StringInstance representing the object, and then calling
        # to_s actually gets the string.
        object.call(:to_s) do |object_as_string|
          Kernel.puts(object_as_string.to_s)
          yield runtime.nil
        end
      end
    end
    
    # Yield the caller's current block
    def primitive_yield(*args, &continuation)
      block = current_call.caller_scope.block
      
      if block
        block.call(:call, args, &continuation)
      else
        raise Carat::CaratError, "no block to yield in #{current_call.inspect}"
      end
    end
    
    # Throw away the current continuation and call the failure continuation
    def primitive_raise(exception, &continuation)
      prepare_to_jump
      current_failure_continuation.call(exception)
    end
    
    # Return from a method on the call stack without doing any further computation
    def primitive_return(value, &continuation)
      prepare_to_jump
      current_return_continuation.call(value)
    end
    
    # Remove the current call and current scope from their respective stacks, as these relate
    # to the method which called this primitive, and we are going to jump somewhere else without
    # returning to that method.
    def prepare_to_jump
      call_stack.pop
      scope_stack.pop
    end
  end
end
