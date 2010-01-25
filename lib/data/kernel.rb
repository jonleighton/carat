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
  end
end
