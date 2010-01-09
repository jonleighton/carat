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
    
    # Execute a node on the stack. Either use the given scope, or the current scope otherwise.
    def execute(node_or_object, scope = nil)
      return self.nil if node_or_object.nil?
      
      if node_or_object.is_a?(Carat::Data::ObjectInstance)
        # We have an immediate value, no need to evaluate it
        node_or_object
      else
        node_or_object.scope = scope || current_scope
        execution_stack.execute(node_or_object)
      end
    end
    
    # Create a +Call+ and execute it on the call stack
    def call(callable, scope, argument_list)
      call = Call.new(self, callable, scope, argument_list)
      call_stack.execute(call)
    end
    
    # Parse some code and then execute its AST
    def run(code)
      ast = Carat.parse(code)
      begin
        execute(ast)
      rescue StandardError => e
        puts "Error: #{e.message}"
        puts e.backtrace[0..10].join("\n")
        puts
        puts "Stack:"
        p execution_stack
      end
    end
    
    # Read the contents of a file and run it
    def run_file(file_name)
      run(File.read(file_name))
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
  end
end
