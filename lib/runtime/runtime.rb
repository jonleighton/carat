module Carat
  class Runtime
    require RUNTIME_PATH + "/scope"
    require RUNTIME_PATH + "/environment"
    require RUNTIME_PATH + "/call"
    
    attr_reader :constants, :call_stack, :scope_stack, :failure_continuation_stack
    
    def initialize
      # The scope containing the top level variables
      @top_level_scope = Scope.new(nil)
      
      # Constants are defined globally
      @constants = {}
      
      # Set up basic environment - default set of classes & objects, etc
      @environment = Environment.new(self)
      @environment.setup
      @initialized = true
      @environment.load_kernel
    end
    
    # The runtime is initialized when the environment has been set up
    def initialized?
      @initialized == true
    end
    
    def current_call
      call_stack.last
    end
    
    def current_scope
      scope_stack.last
    end
    
    def current_failure_continuation
      failure_continuation_stack.last
    end
    
    def current_return_continuation
      current_call.return_continuation
    end
    
    def current_location
      current_call.location
    end
    
    def current_object
      current_scope[:self]
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
      raise ArgumentError, "no continuation given" unless block_given?
      
      call = Call.new(self, location, callable, scope, argument_list)
      call.send(&continuation)
    end
    
    # Raises an exception in the object language
    def raise(exception_name, message, *args)
      args = [constants[:String].new(message)] + args
      constants[exception_name].call(:new, args) do |exception|
        current_failure_continuation.call(exception, current_location)
      end
    end
    
    def default_failure_continuation
      lambda do |exception, location|
        exception.call(:to_s) do |exception_string|
          puts "#{exception.real_klass.name}: #{exception_string}"
          
          locations       = [location] + call_stack.reverse.map(&:location)
          enclosing_calls = call_stack.reverse + [nil]
          backtrace       = locations.zip(enclosing_calls)[0..-2]
          
          backtrace.each do |location, enclosing_call|
            puts "  #{location} in #{enclosing_call}"
          end
          
          exit 1
        end
      end
    end
    
    def main_method(contents)
      argument_pattern = Carat::AST::ArgumentPattern.new
      method = constants[:Method].new(:main, argument_pattern, contents)
      argument_pattern.runtime = contents.runtime = self
      method
    end
    
    def main_object
      constants[:Object].new
    end
    
    def main_scope
      @top_level_scope.extend(main_object)
    end
    
    def call_main_method(contents)
      contents ||= Carat::AST::ExpressionList.new
      call(contents.location, main_method(contents), main_scope) do |final_result|
        nil
      end
    end
    
    # This is the starting point for executing an AST. We reset the various stacks, and then create
    # and call a special 'main' method with the root node as its contents.
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
      @call_stack                 = []
      @scope_stack                = []
      @failure_continuation_stack = [default_failure_continuation]
      
      current_result = call_main_method(root)
      while current_result.is_a?(Proc)
        current_result = current_result.call
      end
    end
    
    # Parse some code and then execute its AST
    def run(input, file_name = nil)
      execute Carat.parse(input, file_name)
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
            puts call_stack.reverse.map(&:inspect).join("\n\n")
        end
        exit 1
      end
  end
end
