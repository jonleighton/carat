module Carat
  class Runtime
    require RUNTIME_PATH + "/scope"
    require RUNTIME_PATH + "/environment"
    require RUNTIME_PATH + "/call"
    
    attr_reader   :constants, :current_call
    attr_accessor :current_scope, :current_ast
    
    def initialize
      # The scope containing the top level variables
      @current_scope = @top_level_scope = Scope.new(nil)
      
      # Constants are defined globally
      @constants       = {}
      
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
    def fold(base, operation, items, limit = nil, &continuation)
      # Set the limit. We will process the items in the range items[0...limit]
      limit ||= items.length
      
      if limit == 0
        # Base case: there are no items to process
        yield base
      else
        # Inductive case: process all the items up to the limit, except the last one. Then combine
        # the last one with the rest according to the 'operation' function provided.
        fold(base, operation, items, limit - 1) do |accumulation|
          operation.call(items[limit - 1], accumulation, &continuation)
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
    
    def execute(root_node)
      @current_ast = root_node
      root_node.runtime = self
      root_node.eval { |final_result| nil }
      @current_ast = nil
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
          puts "AST:"
          p @current_ast
      end
      exit 1
    end
  end
end
