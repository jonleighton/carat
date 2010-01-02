module Carat
  class Runtime
    require RUNTIME_PATH + "/symbol_table"
    require RUNTIME_PATH + "/stack"
    require RUNTIME_PATH + "/frame"
    
    require RUNTIME_PATH + "/environment"
    
    attr_reader :stack, :constants, :top_level_scope
    
    def initialize
      @stack = Stack.new(self)
      
      @constants       = SymbolTable.new
      @top_level_scope = SymbolTable.new
      
      @environment = Environment.new(self)
      @environment.setup
      @initialized = true
      @environment.load_kernel
    end
    
    # The runtime is initialized when the environment has been set up
    def initialized?
      @initialized == true
    end
    
    def current_node
      stack.peek
    end
    
    def execute(ast)
      stack.execute(ast)
    end
    
    def run(code)
      ast = Carat.parse(code)
      Carat.debug "Abstract Syntax Tree:\n#{ast.inspect}\n\n"
      begin
        ast.scope = top_level_scope
        execute(ast)
      rescue StandardError => e
        puts "Error while running:\n#{current_node.inspect}"
        puts "Stack:"
        stack.nodes.each do |node|
          puts " * #{node}"
        end
        raise e
      end
    end
    
    # Converts an object in the metalanguage to a representative object in the object language. For
    # example, an Array would be converted into a Carat::Runtime::Object with
    # klass = constants[:Array]
    #
    # It makes a lot of the code more succinct, as there is (or will be, in a complete implementation)
    # a 1-1 map between classes in the metalanguage and classes in the object language
    def meta_convert(object)
      case object
        when Carat::Data::ObjectInstance # No need to convert
          object
        when Fixnum
          constants[:Fixnum].get(object)
        when Array
          constants[:Array].call(:new, object)
        when String
          Carat::Data::StringInstance.new(self, object)
        when NilClass
          constants[:NilClass].instance
        when FalseClass
          constants[:FalseClass].instance
        when TrueClass
          constants[:TrueClass].instance
        else
          raise Carat::CaratError, "unable to meta convert #{object.inspect}"
      end
    end
    
    def run_file(file_name)
      run(File.read(file_name))
    end
  end
end
