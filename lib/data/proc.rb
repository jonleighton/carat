module Carat::Data
  class ProcClass < ClassInstance
    def primitive_new
      runtime.current_scope.block
    end
  end
  
  class ProcInstance < ObjectInstance
    attr_reader :scope, :args, :contents
  
    def initialize(runtime, scope, args, contents)
      @scope, @args, @contents = scope, args, contents
      super(runtime, runtime.constants[:Proc])
    end
  end
end
