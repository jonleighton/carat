class Carat::Runtime
  class SymbolTable
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
    def [](symbol)
      @symbols[symbol] || @parent && @parent[symbol]
    end
    
    # Assign a value to a symbol
    def []=(symbol, value)
      if @symbols.has_key?(symbol)      # If it exists here, assign it here
        @symbols[symbol] = value
      elsif @parent && @parent[symbol] # If it exists in a parent, assign it there
        @parent.set(symbol, value)
      else                             # Otherwise initialise a fresh symbol here
        @symbols[symbol] = value
      end
    end
    
    # Assign a hash of multiple symbol and value pairs
    def merge!(items)
      @symbols.merge!(items)
    end
    
    # Create a new symbol table, using this one as the parent, containing the given assignment
    def extend(assignments = {})
      SymbolTable.new(self, assignments)
    end
  end
end
