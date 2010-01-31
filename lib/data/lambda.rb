module Carat::Data
  class LambdaClass < ClassInstance
    def new(argument_pattern, contents, scope)
      LambdaInstance.new(runtime, self, argument_pattern, contents, scope)
    end
    
    def primitive_new
      yield current_call.block
    end
  end
  
  class LambdaInstance < ObjectInstance
    attr_reader :argument_pattern, :contents, :scope
    
    def initialize(runtime, klass, argument_pattern, contents, scope)
      @argument_pattern, @contents, @scope = argument_pattern, contents, scope
      super(runtime, klass)
    end
    
    def eval_call(scope, &continuation)
      if contents.nil?
        continuation.call(runtime.nil)
      else
        contents.eval_in_scope(scope, &continuation)
      end
    end
    
    # Extend the scope in which the block was created. The reason for extending the scope is that 
    # it means any fresh variables within the lambda will stay local to the lambda.
    def evaluation_scope
      scope.extend
    end
    
    def to_s
      "<lambda>"
    end
    
    ##### PRIMITIVES #####
    
    def primitive_call(*args, &continuation)
      runtime.call(argument_pattern.location, self, evaluation_scope, args, &continuation)
    end
  end
end
