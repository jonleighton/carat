# Standard Scopes have a parent, and they use the hierarchy to lookup globals
class Carat::Runtime
  class Scope < AbstractScope
    attr_reader :parent
    
    extend Forwardable
    def_delegators :parent, :runtime, :globals, :constants
    
    def initialize(self_object, parent)
      super(self_object)
      @parent  = parent
    end
    
    def [](symbol)
      super || parent[symbol]
    end
  end
end
