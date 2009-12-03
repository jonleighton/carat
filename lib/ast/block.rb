module Carat::AST
  class Block < Node
    attr_reader :children
    
    def initialize(nodes)
      @children = nodes
    end
    
    def inspect
      super + ":\n" + indent(children.map(&:inspect).join("\n"))
    end
  end
end
