# The top level scope takes care of "globals". In this context "globals" can either be constants
# (which are globally available) or actual global variables.
class Carat::Runtime
  class TopLevelScope < AbstractScope
    attr_reader :runtime, :globals
    
    def initialize(runtime)
      super(nil)
      @runtime, @globals = runtime, {}
    end
    
    def [](symbol)
      super || raise(Carat::CaratError, "local variable '#{symbol}' is undefined")
    end
    
    alias_method :constants, :globals
    alias_method :global_variables, :globals
  end
end
