class Carat::Runtime
  class AbstractScope
    attr_reader :symbols
    
    def initialize(self_object)
      @symbols = { :self => self_object }
    end
    
    def [](symbol)
      symbols[symbol]
    end
    
    def has?(symbol)
      symbols[symbol] || false
    end
    
    def []=(symbol, value)
      symbols[symbol] = runtime.meta_convert(value)
    end
    
    def merge!(items)
      items.each do |symbol, value|
        symbols[symbol] = runtime.meta_convert(value)
      end
      items
    end
  end
end
