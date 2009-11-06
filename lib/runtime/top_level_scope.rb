# The top level scope takes care of "globals". In this context "globals" can either be constants
# (which are globally available) or actual global variables.
class Carat::Runtime
  class TopLevelScope
    attr_reader :runtime, :symbols, :globals
    
    def initialize(runtime, self_object)
      @runtime = runtime
      @symbols = { :self => self_object }
      @globals = {}
    end
    
    def initialize_environment
      object_class = constants[:Object] = ObjectClass.new(runtime, :Object, nil)
      constants[:Fixnum] = Fixnum.new(runtime, :Fixnum, object_class)
      constants[:Array] = Array.new(runtime, :Array, object_class)
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
