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
    
    def call(method_name, arguments, &continuation)
      eval_receiver do |receiver_object|
        method = receiver_object.lookup_instance_method(method_name)
        
        if method
          receiver_object.call(method, arguments, location, &continuation)
        else
          runtime.raise :NoMethodError, "undefined method '#{method_name}' for object #{receiver_object}", location
        end
      end
    end
    
    def eval(&continuation)
      call(name, arguments, &continuation)
    end
    
    def assign(value, &continuation)
      assign_arguments = Carat::AST::ArgumentList.new(
        location, arguments.items + [
          Carat::AST::ArgumentList::Item.new(location, value)
        ]
      )
      assign_arguments.runtime = runtime
      
      call("#{name}=".to_sym, assign_arguments, &continuation)
    end
  end
  
  class ArgumentList < NodeList
    class Item < Node
      child    :expression
      property :type, :default => :normal
      
      def eval(&continuation)
        if expression.is_a?(Node)
          eval_child(expression, &continuation)
        else
          yield expression
        end
      end
    end
    
    def eval(&continuation)
      append = lambda do |object, arguments, node, &append_continuation|
        case node.type
          when :splat
            object.call(:to_a) do |object_as_array|
              arguments.values += object_as_array.contents
              append_continuation.call(arguments)
            end
          when :block, :block_pass
            arguments.block = object
            append_continuation.call(arguments)
          else
            arguments.values << object
            append_continuation.call(arguments)
        end
      end
      
      eval_fold(Carat::Runtime::Call::Arguments.new, append, &continuation)
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
