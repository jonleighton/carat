# Standard Scopes have a parent, and they use the hierarchy to lookup globals
class Carat::Runtime
  class Scope < TopLevelScope
    attr_reader :parent
    
    extend Forwardable
    def_delegators :parent, :runtime, :globals
    
    def initialize(self_object, parent)
      super(self_object)
      @parent = parent
    end
    
    def [](symbol)
      symbols[symbol] || parent[symbol]
    end
  end
end
