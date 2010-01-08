class Carat::Runtime
  class Scope
    attr_reader :symbols, :parent
    attr_writer :block
    
    def initialize(self_object = nil, parent = nil)
      @symbols = { :self => self_object }
      @parent  = parent
    end
    
    # Get a symbol from this scope or parent scope. May return nil.
    def [](symbol)
      @symbols[symbol] || @parent && @parent[symbol]
    end
    
    # Assign a value to a symbol
    def []=(symbol, value)
      if @symbols.has_key?(symbol)     # If it exists here, assign it here
        @symbols[symbol] = value
      elsif @parent && @parent[symbol] # If it exists in a parent, assign it there
        @parent[symbol] = value
      else                             # Otherwise initialise a fresh symbol here
        @symbols[symbol] = value
      end
    end
    
    # Assign a hash of multiple symbol and value pairs
    def merge!(items)
      items.each do |symbol, value|
        self[symbol] = value
      end
    end
    
    # Get the current block in this scope - this is inherited from parent scopes if there is no
    # block set in this scope
    def block
      @block || @parent && @parent.block
    end
    
    # Create a new scope using this one as the parent
    def extend(self_object = nil)
      Scope.new(self_object, self)
    end
  end
end
