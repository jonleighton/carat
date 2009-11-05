module Carat
  class Runtime
    %w[top_level_scope scope stack frame].each do |file|
      require RUNTIME_PATH + "/" + file
    end
    
    %w[object class method].each do |file|
      require RUNTIME_PATH + "/data/" + file
    end
    
    def initialize
      @scope = TopLevelScope.new(nil)
    end
    
    def eval(sexp)
      @stack = Stack.new
      @frame = Frame.new(sexp, @scope)
      @stack << @frame
    end
  end
end
