# The top level scope takes care of "globals". In this context "globals" can either be constants
# (which are globally available) or actual global variables.
class Carat::Runtime
  class TopLevelScope
    attr_reader :symbols, :globals
    
    def initialize(self_object)
      @symbols = { :self => self_object }
      @globals = {}
    end
    
    def []=(symbol, value)
      symbols[symbol] = value
    end
    
    def [](symbol)
      symbols[symbol] || raise(CaratError, "local variable '#{symbol}' is undefined")
    end
    
    # TODO: Make this work
    # For now:
    alias_method :constants, :globals
    alias_method :global_variables, :globals
=begin
    def constants[]=(symbol, value)
      globals[symbol] = value
    end
    
    def constants[](symbol)
      globals[symbol] || raise(CaratError, "constant '#{symbol}' is undefined")
    end
    
    def global_variables[]=(symbol, value)
      globals[symbol] = value
    end
    
    def global_variables[](symbol)
      globals[symbol] || raise(CaratError, "global variable '#{symbol}' is undefined")
    end
=end
  end
end
