# Standard Scopes have a parent, and they use the hierarchy to lookup globals
class Carat::Runtime
  class Scope < AbstractScope
    attr_reader :parent
    attr_accessor :block
    
    extend Forwardable
    def_delegators :parent, :runtime, :globals, :constants
    
    def initialize(self_object, parent, block = nil)
      @parent, @block = parent, block
      super(self_object)
    end
    
    def [](symbol)
      super || parent[symbol]
    end
    
    def has?(symbol)
      super || parent.has?(symbol)
    end
  end
end
