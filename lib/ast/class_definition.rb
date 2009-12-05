module Carat::AST
  class ClassDefinition < Node
    attr_reader :name, :superclass, :contents
    
    def initialize(name, superclass, contents)
      @name, @superclass, @contents = name, superclass, contents
    end
    
    def inspect
      super + "[#{name}]:\n" +
        "Superclass:\n" + indent(superclass.inspect) + "\n" +
        "Contents:\n"   + indent(contents.inspect)
    end
  end
end
