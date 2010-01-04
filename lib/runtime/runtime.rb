module Carat
  class Runtime
    require RUNTIME_PATH + "/symbol_table"
    require RUNTIME_PATH + "/stack"
    require RUNTIME_PATH + "/frame"
    require RUNTIME_PATH + "/environment"
    require RUNTIME_PATH + "/call"
    
    attr_reader :constants
    
    def initialize
      # The stack containing the AST nodes which are currently being executed
      @execution_stack = ExecutionStack.new(self)
      
      # The stack containing Call objects representing the current chain of method calls
      @call_stack      = CallStack.new
      
      # The SymbolTable containing the top level variables
      @top_level_scope = SymbolTable.new
      
      # The SymbolTable containing all the constants in the runtime. (Constants are defined
      # globally)
      @constants       = SymbolTable.new
      
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
      @execution_stack.peek
    end
    
    # The scope in which the current node is executed
    def current_scope
      current_node && current_node.scope || @top_level_scope
    end
    
    # The top-most item in the call stack
    def current_call
      @call_stack.peek
    end
    
    # Execute a node on the stack. Either use the given scope, or the current scope otherwise.
    def execute(node_or_object, scope = nil)
      return nil if node_or_object.nil?
      
      if node_or_object.is_a?(Carat::Data::ObjectInstance)
        # We have an immediate value, no need to evaluate it
        node_or_object
      else
        node_or_object.scope = scope || current_scope
        @execution_stack.execute(node_or_object)
      end
    end
    
    # Create a +Call+ and execute it on the call stack
    def call(callable, scope, argument_list)
      call = Call.new(self, callable, scope, argument_list)
      @call_stack.execute(call)
    end
    
    # Parse some code and then execute its AST
    def run(code)
      ast = Carat.parse(code)
      Carat.debug "Abstract Syntax Tree:\n#{ast.inspect}\n\n"
      begin
        execute(ast)
      rescue StandardError => e
        puts "Error while running:\n#{current_node.inspect}"
        puts "Stack:"
        @execution_stack.each_item do |node|
          puts " * #{node}"
        end
        raise e
      end
    end
    
    # Read the contents of a file and run it
    def run_file(file_name)
      run(File.read(file_name))
    end
  end
end
