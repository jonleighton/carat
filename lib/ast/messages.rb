module Carat::AST
  class MethodCall < Node
    attr_reader :receiver, :name, :arguments
    
    def initialize(receiver, name, arguments)
      @receiver, @name, @arguments = receiver, name, arguments
    end
    
    def inspect
      super + "[#{name}]:\n" +
        "  Receiver:\n" + indent(indent(receiver.inspect)) + "\n" +
        indent(arguments.inspect)
    end
  end
  
  class ArgumentList < NodeList
    attr_accessor :block
    
    def initialize(items = [], block = nil)
      super(items)
      @block = block
    end
    
    def inspect
      super + (block && "\n#{indent(block.inspect)}" || '')
    end
  end
  
  class Block < Node
    attr_reader :argument_pattern, :contents
    
    def initialize(argument_pattern, contents)
      @argument_pattern, @contents = argument_pattern, contents
    end
    
    def inspect
      super + ":\n" + 
      indent(argument_pattern.inspect) + "\n" +
      indent(contents.inspect)
    end
  end
  
  class Splat < ExpressionNode
  end
  
  class BlockPass < ExpressionNode
  end
end
