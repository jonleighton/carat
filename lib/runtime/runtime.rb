module Carat
  class Runtime
    %w[top_level_scope scope stack frame].each do |file|
      require RUNTIME_PATH + "/" + file
    end
    
    %w[object class method primitive].each do |file|
      require RUNTIME_PATH + "/data/" + file
    end
    
    %w[array].each do |file|
      require RUNTIME_PATH + "/primitives/" + file
    end
    
    def initialize
      @stack = Stack.new
      @top_level_scope = TopLevelScope.new(nil)
      @top_level_scope.initialize_environment
    end
    
    def run(code)
      sexp = Carat.parse(code)
      Carat.debug "Running sexp: #{sexp.inspect}"
      @frame = Frame.new(sexp, @top_level_scope)
      @stack << @frame
    end
    
    def run_file(file_name)
      run(File.read(file_name))
    end
  end
end
