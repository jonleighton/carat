class Carat::Runtime
  class SymbolTable
    attr_reader :symbols, :parent
    attr_accessor :block
    
    # Can be initialized with or without a parent, and with a list of assignments. For example:
    # 
    #   SymbolTable.new
    #   SymbolTable.new(parent)
    #   SymbolTable.new(:foo => :bar)
    #   SymbolTable.new(parent, :foo => :bar)
    def initialize(*args)
      @parent = args.first.is_a?(Hash) ? nil : args.shift
      @symbols = args.last || {}
    end
    
    # Get a symbol from this table or parent table. May return nil.
    def get(symbol)
      symbols[symbol] || parent && parent.get(symbol)
    end
    
    # Set a symbol in this table or the parent table. Returns nil if the symbol is not found.
    def set(symbol, value)
      if symbols.has_key?(symbol)
        symbols[symbol] = value
      else
        parent && parent.set(symbol, value)
      end
    end
    
    # Look up a symbol, return nil if failure
    def [](symbol)
      get(symbol) || raise(Carat::CaratError, "symbol '#{symbol}' is undefined")
    end
    
    # Try to get the symbol, return true if it exists, and false otherwise
    def has?(symbol)
      get(symbol) && true || false
    end
    
    # Assign a value to a symbol. If the symbol exists in a parent then it gets assigned there,
    # rather than overridden at this level.
    def []=(symbol, value)
      set(symbol, value) || symbols[symbol] = value
    end
    
    # Assign a hash of multiple symbol and value pairs
    def merge!(items)
      symbols.merge!(items)
    end
    
    # Create a new symbol table, using this one as the parent, containing the given assignment
    def extend(assignments = {})
      SymbolTable.new(self, assignments)
    end
  end
end
