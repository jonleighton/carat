module Carat
  class Runtime
    %w[abstract_scope top_level_scope scope stack frame environment].each do |file|
      require RUNTIME_PATH + "/" + file
    end
    
    require DATA_PATH + "/data"
    
    attr_reader :stack, :top_level_scope
    
    extend Forwardable
    def_delegators :top_level_scope, :constants
    def_delegators :current_scope, :symbols
    def_delegators :current_frame, :eval, :meta_convert
    
    def initialize
      @stack = Stack.new
      @top_level_scope = TopLevelScope.new(self)
      @environment = Environment.new(self)
      @environment.setup
      @initialized = true
      @environment.load_kernel
    end
    
    def current_scope
      current_frame && current_frame.scope || top_level_scope
    end
    
    def current_frame
      stack.peek
    end
    
    def initialized?
      @initialized == true
    end
    
    def run(code)
      sexp = Carat.parse(code)
      Carat.debug "Running sexp: #{sexp.inspect}"
      begin
        stack << Frame.new(sexp, @top_level_scope)
      rescue StandardError => e
        puts "Error while running: #{current_frame.sexp.inspect}"
        raise e
      end
    end
    
    def run_file(file_name)
      run(File.read(file_name))
    end
  end
end
