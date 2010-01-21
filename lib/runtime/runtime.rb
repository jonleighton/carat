module Carat
  class Runtime
    require RUNTIME_PATH + "/scope"
    require RUNTIME_PATH + "/stack"
    require RUNTIME_PATH + "/environment"
    require RUNTIME_PATH + "/call"
    
    attr_reader :constants, :call_stack, :execution_stack
    
    def initialize
      # The stack containing the AST nodes which are currently being executed
      @execution_stack = ExecutionStack.new(self)
      
      # The stack containing Call objects representing the current chain of method calls
      @call_stack      = CallStack.new
      
      # The scope containing the top level variables
      @top_level_scope = Scope.new(nil)
      
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
    
    # The top-most AST node being executed
    def current_node
      execution_stack.peek
    end
    
    # The scope in which the current node is executed
    def current_scope
      current_node && current_node.scope || @top_level_scope
    end
    
    def current_object
      current_scope[:self]
    end
    
    # The top-most item in the call stack
    def current_call
      call_stack.peek
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
    
    def final_continuation
      lambda do |value|
        puts "Finished: #{value}"
      end
    end
    
    def execute(root_node)
      root_node.eval_in_runtime(self, @top_level_scope, &final_continuation)
    end
    
    # Create a +Call+ and execute it on the call stack
    def call(callable, scope, argument_list, &continuation)
      call = Call.new(self, callable, scope, argument_list, &continuation)
      call_stack.execute(call)
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
          puts exception.backtrace.join("\n")
          puts
          puts "Stack:"
          p execution_stack
      end
      exit 1
    end
  end
end
