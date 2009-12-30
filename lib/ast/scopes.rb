module Carat::AST
  class ExpressionList < NodeList
  end
  
  class ModuleDefinition < Node
    attr_reader :name, :contents
    
    def initialize(name, contents)
      @name, @contents = name, contents
    end
    
    def inspect
      super + "[#{name}]:\n" + indent(contents.inspect)
    end
  end
  
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
  
  class MethodDefinition < Node
    attr_reader :receiver, :name, :argument_pattern, :contents
    
    def initialize(receiver, name, argument_pattern, contents)
      @receiver, @name, @argument_pattern, @contents = receiver, name, argument_pattern, contents
    end
    
    def inspect
      super + "[#{name}]:\n" +
        "Receiver:\n" + indent(receiver.inspect) + "\n" +
        argument_pattern.inspect + "\n" +
        "Contents:\n" + indent(contents.inspect)
    end
  end
  
  class ArgumentPattern < NodeList
    attr_reader :block_pass
    
    def initialize(items = [], block_pass = nil)
      super(items)
      @block_pass = block_pass
    end
    
    def inspect
      super + (block_pass && "\n" + indent("Block Pass: #{block_pass}") || "")
    end
  end
  
  class ArgumentPatternItem < Node
    attr_reader :name, :default
    
    def initialize(name, default)
      @name, @default = name, default
    end
    
    def inspect
      super + "[#{name}]" + (default && " = \n" + indent(default.inspect) || '')
    end
  end
  
  class SplatArgumentPatternItem < NamedNode
  end
end
