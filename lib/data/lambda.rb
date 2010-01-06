module Carat::Data
  class LambdaClass < ClassInstance
    def primitive_new
      scope.block
    end
  end
  
  class LambdaInstance < ObjectInstance
    attr_reader :argument_pattern, :contents, :scope
    
    def initialize(runtime, argument_pattern, contents, scope)
      @argument_pattern, @contents, @scope = argument_pattern, contents, scope
      super(runtime, runtime.constants[:Lambda])
    end
    
    def evaluation_scope
      scope.extend(:self => self)
    end
    
    ##### PRIMITIVES #####
    
    def primitive_call(*args)
      runtime.call(self, evaluation_scope, args)
    end
  end
end
