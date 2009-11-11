module Carat
  class Runtime
    %w[abstract_scope top_level_scope scope stack frame environment bootstrap].each do |file|
      require RUNTIME_PATH + "/" + file
    end
    
    %w[object class singleton_class meta_class method primitive].each do |file|
      require RUNTIME_PATH + "/data/" + file
    end
    
    attr_reader :stack, :top_level_scope
    
    extend Forwardable
    def_delegators :top_level_scope, :constants
    def_delegators :current_frame, :new_instance, :symbols
    
    def initialize
      @stack = Stack.new
      @top_level_scope = TopLevelScope.new(self, nil)
      @environment = Environment.new(self)
      @environment.setup
      @initialized = true
      @environment.load_kernel
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
