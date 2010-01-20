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
    class Item < Node
      attr_accessor :expression, :argument_type
      
      def initialize(expression, argument_type = :normal)
        @expression, @argument_type = expression, argument_type
      end
      
      def inspect
        type + "[#{argument_type}]:\n" + indent(expression.inspect)
      end
    end
    
    def initialize(items = [])
      super(items)
    end
    
    def block
      if items.last && (items.last.argument_type == :block ||
                        items.last.argument_type == :block_pass)
        items.last.expression
      end
    end
    
    def non_block_items
      if block.nil?
        items
      else
        items[0..-2]
      end
    end
    
    def eval
      non_block_items.inject([]) do |argument_objects, item|
        if item.argument_type == :splat
          argument_objects += execute(item.expression).call(:to_a).contents
        else
          argument_objects << execute(item.expression)
        end
      end
    end
  end
  
  # This is a literal block, i.e. "foo do .. end" or "foo { ... }"
  # When evaluated it is converted to a lambda
  class Block < Node
    attr_reader :argument_pattern, :contents
    
    def initialize(argument_pattern, contents)
      @argument_pattern, @contents = argument_pattern, contents
    end
    
    def eval
      Carat::Data::LambdaInstance.new(runtime, argument_pattern, contents, scope)
    end
    
    def inspect
      type + ":\n" + 
      indent(argument_pattern.inspect) + "\n" +
      indent(contents.inspect)
    end
  end
  
  class Splat < Node
    attr_reader :expression
      
    def initialize(expression)
      @expression = expression
    end
    
    def items
      execute(expression).call(:to_a)
    end
      
    def inspect
      type + ":\n" + indent(expression.inspect)
    end
  end
end
