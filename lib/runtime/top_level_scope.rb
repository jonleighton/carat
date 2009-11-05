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
      symbols[symbol] || raise(Carat::CaratError, "local variable '#{symbol}' is undefined")
    end
    
    def merge!(items)
      symbols.merge!(items)
    end
    
    alias_method :constants, :globals
    alias_method :global_variables, :globals
  end
end
