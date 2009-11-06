module Carat
  class Runtime
    %w[top_level_scope scope stack frame].each do |file|
      require RUNTIME_PATH + "/" + file
    end
    
    %w[object class method primitive].each do |file|
      require RUNTIME_PATH + "/data/" + file
    end
    
    %w[object_class array fixnum].each do |file|
      require RUNTIME_PATH + "/primitives/" + file
    end
    
    attr_reader :stack, :top_level_scope
    
    extend Forwardable
    def_delegators :top_level_scope, :constants
    def_delegators :current_frame, :new_instance
    
    def initialize
      @stack = Stack.new
      @top_level_scope = TopLevelScope.new(self, nil)
      @top_level_scope.initialize_environment
    end
    
    def current_frame
      stack.peek
    end
    
    def run(code)
      sexp = Carat.parse(code)
      Carat.debug "Running sexp: #{sexp.inspect}"
      stack << Frame.new(sexp, @top_level_scope)
    rescue StandardError => e
      puts "Error while running: #{current_frame.sexp.inspect}"
      raise e
    end
    
    def run_file(file_name)
      run(File.read(file_name))
    end
  end
end
