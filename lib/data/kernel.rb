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
        block.primitive_call(*args, &continuation)
      else
        raise Carat::CaratError, "no block to yield in #{current_call.inspect}"
      end
    end
    
    # Throw away the current continuation and call the failure continuation
    def primitive_raise(&continuation)
      runtime.failure_continuation.call
    end
    
    # Throw away the current continuation and call the previous call's return continuation. (We
    # don't use the return continuation for the current call, as that will be the call to 
    # Carat.primitive which invoked the primitive.)
    def primitive_return(value, &continuation)
      call_stack[-2].return_continuation.call(value)
    end
  end
end
