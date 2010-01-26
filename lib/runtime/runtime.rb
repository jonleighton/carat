module Carat
  class Runtime
    require RUNTIME_PATH + "/scope"
    require RUNTIME_PATH + "/environment"
    require RUNTIME_PATH + "/call"
    
    attr_reader   :constants, :current_call, :ast_stack
    attr_accessor :current_scope, :failure_continuation
    
    def initialize
      # The scope containing the top level variables
      @current_scope = @top_level_scope = Scope.new(nil)
      
      # Constants are defined globally
      @constants       = {}
      
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
          fold(next_answer, operation, items, start + 1, &continuation)
        end
      end
    end
    
    # This is an 'each' function written in continuation passing style
    def each(operation, items, final_answer, start = 0, &continuation)
      if start == items.length
        yield final_answer
      else
        operation.call(items[start]) do
          each(operation, items, final_answer, start + 1, &continuation)
        end
      end
    end
    
    # Create a +Call+ and send it
    def call(callable, scope, argument_list, &continuation)
      raise ArgumentError, "no continuation given" unless block_given?
      
      previous_call = @current_call
      @current_call = Call.new(self, callable, scope, argument_list)
      @current_call.send do |result|
        @current_call = previous_call
        yield result
      end
    end
    
    # This is the starting point for executing an AST. Every time we decend into a method call, we
    # are executing a new AST before returning to the previous one. We track this in @ast_stack for
    # debugging.
    # 
    # AST nodes need a reference to the runtime in order to be evaluated. We set the runtime on the
    # root node, and it handles recursively setting the runtime on all decendent nodes.
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
    def execute(root_node)
      @ast_stack = [root_node]
      root_node.runtime = self
      self.failure_continuation = lambda do
        puts "Exception raised"
      end
      
      current_result = root_node.eval { |final_result| nil }
      while current_result.is_a?(Proc)
        current_result = current_result.call
      end
      
      @ast_stack = []
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
    
    def handle_error(exception)
      case exception
        when SyntaxError
          puts exception.full_message
        else
          puts "Error: #{exception.message}"
          puts exception.backtrace[0..40].join("\n")
          puts "[Backtrace truncated]" if exception.backtrace.length > 40
          puts
          puts "AST stack:"
          ast_stack.each do |ast|
            p ast
            puts
          end
      end
      exit 1
    end
  end
end
