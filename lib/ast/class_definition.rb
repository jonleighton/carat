module Carat::AST
  class ClassDefinition < Node
    attr_reader :name, :contents
    
    def initialize(name, contents)
      @name, @contents = name, contents
    end
    
    def inspect
      super + "[#{name}]:\n" + indent(contents.inspect)
    end
  end
end
