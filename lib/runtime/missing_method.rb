class Carat::Runtime
  # MissingMethod represents a call to a MethodCall or LocalVariableOrMethodCall which must fail
  # because no matching method has been found.
  class MissingMethod
    attr_reader :runtime, :receiver, :name, :error
    
    def initialize(runtime, receiver, name, error)
      @runtime, @receiver, @name, @error = runtime, receiver, name, error
    end
    
    def argument_pattern
      @argument_pattern ||= begin
        item = Carat::AST::ArgumentPattern::Item.new(nil, :args, :splat)
        pattern = Carat::AST::ArgumentPattern.new(nil, [item])
        item.runtime = pattern.runtime = runtime
        pattern
      end
    end
    
    def call(scope, &continuation)
      runtime.raise(error, runtime.constants[:String].new(name))
    end
    
    def to_s
      "<missing_method:#{name}>"
    end
  end
end
