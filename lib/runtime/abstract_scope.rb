class Carat::Runtime
  class AbstractScope
    attr_reader :symbols
    
    def initialize(self_object)
      @symbols = { :self => self_object }
    end
    
    def [](symbol)
      symbols[symbol]
    end
    
    def []=(symbol, value)
      symbols[symbol] = value
    end
    
    def merge!(items)
      symbols.merge!(items)
    end
  end
end
