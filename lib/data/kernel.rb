module Carat::Data
  module KernelModule
    def primitive_puts(object)
      if object == runtime.nil
        Kernel.puts("nil")
      else
        # object.call(:to_s) gets the StringInstance representing the object, and then calling
        # to_s actually gets the string.
        Kernel.puts(object.call(:to_s).to_s)
      end
      
      runtime.nil
    end
    
    # Yield the caller's current block
    def primitive_yield(*args)
      block = current_call.caller_scope.block
      if block
        block.primitive_call(*args)
      else
        raise Carat::CaratError, "no block to yield in #{current_call.inspect}"
      end
    end
  end
end
