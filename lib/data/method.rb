module Carat::Data
  class MethodClass < ClassInstance
  end
  
  class MethodInstance < ObjectInstance
    attr_reader :name, :argument_pattern, :contents
    
    def initialize(runtime, name, argument_pattern, contents)
      @name, @argument_pattern, @contents = name, argument_pattern, contents
      super(runtime, runtime.constants[:Method])
    end
    
    def call(scope, &continuation)
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
