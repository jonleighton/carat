# Standard Scopes have a parent, and they use the hierarchy to lookup globals
class Carat::Runtime
  class Scope < TopLevelScope
    attr_reader :parent
    
    def initialize(self_object, parent)
      super(self_object)
      @parent = parent
    end
    
    def globals
      parent.globals
    end
    
    def [](symbol)
      symbols[symbol] || parent[symbol]
    end
  end
end
