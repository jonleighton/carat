module Carat::AST
  class MethodCall < Node
    attr_reader :receiver, :name, :arguments
    
    def initialize(receiver, name, arguments)
      @receiver, @name, @arguments = receiver, name, arguments
    end
    
    def receiver_object
      receiver && execute(receiver) || scope[:self]
    end
    
    def eval
      receiver_object.call(name, arguments)
    end
    
    def inspect
      type + "[#{name}]:\n" +
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
    
    def eval
      items.map { |expression| execute(expression) }
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
      type + ":\n" + 
      indent(argument_pattern.inspect) + "\n" +
      indent(contents.inspect)
    end
  end
  
  class Splat < ExpressionNode
  end
  
  class BlockPass < ExpressionNode
  end
  
  # This is a special node which allows a meta-language method to be called within a given
  # scope on the stack. It is used for executing primitives in the correct scope.
  class SendMethod < Node
    attr_reader :object, :method_name, :args
  
    def initialize(object, method_name, *args)
      @object, @method_name, @args = object, method_name, args
    end
    
    def eval
      object.send(method_name, *args)
    end
    
    def inspect
      type + "[#{object}.#{method_name}(#{args.join(', ')})]"
    end
  end
end
