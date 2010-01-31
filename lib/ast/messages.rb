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
  end
  
  class ArgumentList < NodeList
    class Item < Node
      child    :expression
      property :type, :default => :normal
      
      def eval(&continuation)
        eval_child(expression, &continuation)
      end
    end
    
    def block
      if items.last && (items.last.type == :block || items.last.type == :block_pass)
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
        if node.type == :splat
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
      yield constants[:Lambda].new(argument_pattern, contents, current_scope)
    end
  end
end
