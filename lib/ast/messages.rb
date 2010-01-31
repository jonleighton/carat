module Carat::AST
  class MethodCall < Node
    child :receiver
    property :name
    child :arguments
    
    def eval_receiver(&continuation)
      if receiver
        eval_child(receiver, &continuation)
      else
        yield current_object
      end
    end
    
    def eval(&continuation)
      eval_receiver do |receiver_object|
        receiver_object.call(name, arguments, location, &continuation)
      end
    end
    
    def inspect
      type + "[#{name}]:\n" +
        "  Receiver:\n" + indent(indent(receiver.inspect)) + "\n" +
        indent(arguments.inspect)
    end
  end
  
  class ArgumentList < NodeList
    class Item < Node
      child    :expression
      property :argument_type, :default => :normal
      
      def eval(&continuation)
        eval_child(expression, &continuation)
      end
      
      def inspect
        type + "[#{argument_type}]:\n" + indent(expression.inspect)
      end
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
    
    def eval(&continuation)
      append = lambda do |object, arguments, node, &append_continuation|
        if node.argument_type == :splat
          object.call(:to_a) do |object_as_array|
            arguments += object_as_array.contents
            append_continuation.call(arguments)
          end
        else
          append_continuation.call(arguments << object)
        end
      end
      
      eval_fold([], append, non_block_items, &continuation)
    end
  end
  
  # This is a literal block, i.e. "foo do .. end" or "foo { ... }"
  # When evaluated it is converted to a lambda
  class Block < Node
    child :argument_pattern
    child :contents
    
    def eval
      yield Carat::Data::LambdaInstance.new(runtime, argument_pattern, contents, current_scope)
    end
    
    def inspect
      type + ":\n" + 
      indent(argument_pattern.inspect) + "\n" +
      indent(contents.inspect)
    end
  end
end
