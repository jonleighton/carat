module Carat
  class Runtime
    require RUNTIME_PATH + "/kernel_loader"
    require RUNTIME_PATH + "/scope"
    require RUNTIME_PATH + "/call"
    require RUNTIME_PATH + "/stack"
    
    attr_reader :stack, :constants, :accessed_files
    
    extend Forwardable
    def_delegators :stack, :current_scope, :current_call, :current_failure_continuation
    
    def initialize
      # Constants are defined globally
      @constants = {}
      
      # Keep track of which additional files have been accessed
      @accessed_files = []
      
      # Load core classes
      KernelLoader.new(self).run
    end
    
    def current_location
      current_call.location
    end
    
    def current_object
      current_scope[:self]
    end
    
    # Returns a list of calls from the stack. (Note that not all stack frames have a call associated
    # with them.)
    def call_stack
      stack.to_a.map(&:call).compact
    end
    
    def false
      constants[:FalseClass].instance
    end
    
    def true
      constants[:TrueClass].instance
    end
    
    def nil
      constants[:NilClass].instance
    end
    
    # This is similar to a 'foldl' or 'inject' function, but written for this specific context
    # where we are using continuation passing style
    def fold(current_answer, operation, items, start = 0, &continuation)
      if start == items.length
        # ** Base Case ** #
        # There are no items to process because we have got to the end of the array, so yield the
        # current answer to the continuation, taking us out of the fold operation
        yield current_answer
      else
        # ** Inductive Case ** #
        # Pass the first item in items[start...items.length], along with the current answer, to the
        # operation. The operation should combine them in some way to form the next answer, before
        # yielding to its continuation, which will then fold items[(start+1)...items.length].
        operation.call(items[start], current_answer) do |next_answer|
          lambda do
            fold(next_answer, operation, items, start + 1, &continuation)
          end
        end
      end
    end
    
    # This is an 'each' function written in continuation passing style
    def each(operation, items, final_answer, start = 0, &continuation)
      if start == items.length
        yield final_answer
      else
        operation.call(items[start]) do
          lambda do
            each(operation, items, final_answer, start + 1, &continuation)
          end
        end
      end
    end
    
    # Create a +Call+ and send it
    def call(location, callable, scope, argument_list = [], &continuation)
      call = Call.new(self, location, callable, scope, argument_list, &continuation)
      call.send
    end
    
    # Raises an exception in the object language
    def raise(exception_name, message)
      constants[exception_name].call(:new, [message]) do |exception|
        exception.generate_backtrace(current_location)
        stack.unwind_to(:failure_continuation)
        current_failure_continuation.call(exception)
      end
    end
    
    def default_failure_continuation
      lambda do |exception|
        exception.call(:to_s) do |exception_string|
          puts "#{exception.real_klass.name}: #{exception_string}"
          puts exception.backtrace.map { |line| "  " + line }.join("\n")
          exit 1
        end
      end
    end
    
    def call_main_method(contents)
      scope = Scope.new(constants[:Object].new)
      call  = MainMethodCall.new(contents.location)
      frame = Frame.new(scope, call, default_failure_continuation)
      
      contents.runtime = self
      contents.eval_in_frame(frame) { |final_result| nil }
    end
    
    # This is the starting point for executing an AST.
    # 
    # Normally, in Continuation Passing Style, a stack of continuations is built up right until the
    # end of the program when they all collapse in to provide the result. In languages without tail
    # call optimisation (such as Ruby 1.8), this quickly leads to an enourmous stack, and it's not
    # hard to create programs which cause the interpreter to run out of stack space.
    # 
    # Therefore, instead of waiting until right at the end of the program to return the answer,
    # we can at any point return a "partial answer" which is just a lambda which can be called to
    # continue the execution of the program. This collapses the call stack right back down, so
    # solves the problem of tail call recursion. This is what the while loop is doing. This
    # technique is called "trampolining".
    def execute(root)
      @stack = Stack.new
      
      current_result = call_main_method(root)
      while current_result.is_a?(Proc)
        current_result = current_result.call
      end
    end
    
    # Parse some code and then execute its AST
    def run(input, file_name = nil)
      execute(Carat.parse(input, file_name))
    rescue StandardError => e
      handle_error(e)
    end
    
    # Read the contents of a file and run it
    def run_file(name)
      run(File.read(name), name)
    end
    
    private
      
      def handle_error(exception)
        case exception
          when SyntaxError
            puts exception.full_message
          else
            puts "Error: #{exception.message}"
            puts exception.backtrace[0..40].join("\n")
            puts "[Backtrace truncated]" if exception.backtrace.length > 40
            puts
            puts "Call Stack"
            puts "=========="
            puts
            puts call_stack.reverse.map(&:inspect).join("\n")
        end
        exit 1
      end
  end
end
