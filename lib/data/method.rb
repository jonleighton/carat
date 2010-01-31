module Carat::Data
  class MethodClass < ClassInstance
    def new(name, argument_pattern, contents)
      MethodInstance.new(runtime, self, name, argument_pattern, contents)
    end
  end
  
  class MethodInstance < ObjectInstance
    attr_reader :name, :argument_pattern, :contents
    
    def initialize(runtime, klass, name, argument_pattern, contents)
      @name, @argument_pattern, @contents = name, argument_pattern, contents
      super(runtime, klass)
    end
    
    def eval_call(scope, &continuation)
      if contents.nil?
        continuation.call(runtime.nil)
      else
        contents.eval_in_scope(scope, &continuation)
      end
    end
    
    def to_s
      "<method:#{name}>"
    end
  end
end
