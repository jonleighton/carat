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
        runtime.raise :ArgumentError, "no block given"
      end
    end
    
    # Throw away the current continuation and call the failure continuation
    def primitive_raise(exception, &continuation)
      # Store the location of the call to Kernel#raise
      location = current_location
      
      # Remove the frame for the Kernel#raise call
      stack.pop
      
      # Generate the exception's backtrace before we modify the stack
      exception.generate_backtrace(location)
      
      # Unwind the stack until we get to a failure continuation
      stack.unwind_to(:failure_continuation)
      
      # Call the failure continuation which is now at the top of the stack
      current_failure_continuation.call(exception)
    end
    
    # Return from a method on the call stack without doing any further computation
    def primitive_return(value, &continuation)
      # Remove the frame for the Kernel#return call
      stack.pop
      
      # Unwind the stack until we get to a call
      stack.unwind_to(:call)
      
      # Call the return continuation of the current call (which will take care of popping the call
      # off the stack)
      current_call.return_continuation.call(value)
    end
    
    def primitive_require(file, &continuation)
      file_location = File.dirname(current_location.file_name) + "/" + file.to_s
      
      if runtime.loaded_files.include?(file_location)
        yield runtime.false
      else
        runtime.run_file(file_location + ".carat")
        yield runtime.true
      end
    end
  end
end
