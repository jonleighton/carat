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
        #block.primitive_call(*args, &continuation)
        block.call(:call, args, &continuation)
      else
        raise Carat::CaratError, "no block to yield in #{current_call.inspect}"
      end
    end
    
    # Throw away the current continuation and call the failure continuation
    def primitive_raise(exception, &continuation)
      runtime.failure_continuation.call(exception)
    end
    
    # Return from a method on the call stack without doing any further computation
    def primitive_return(value, &continuation)
      # Remove the call to this primitive from the call stack
      call_stack.pop
      
      # The call now at the top of the call stack is the call we actually want to return from. We
      # don't explicitly remove it as that's the job of the return continuation.
      call_stack.last.return_continuation.call(value)
    end
  end
end
