module Carat::Data
  class PrimitiveClass < ClassInstance
    def lookup_instance_method(name)
      primitive_name = "primitive_#{name}"
      current_object.method(primitive_name) if current_object.respond_to?(primitive_name)
    end
    
    # This is a special version of call which only dispatches primitives
    def call(method_or_name, argument_list = [], location = nil, &continuation)
      if method_or_name.is_a?(Method)
        method = method_or_name
      else
        method = lookup_instance_method!(method_or_name)
      end
      
      eval_arguments(argument_list) do |arguments|
        send_primitive(method, arguments, &continuation)
      end
    end
    
    def eval_arguments(argument_list, &continuation)
      if argument_list.is_a?(Carat::AST::ArgumentList)
        argument_list.eval do |arguments|
          yield arguments.values
        end
      else
        yield argument_list
      end
    end
    
    def send_primitive(method, arguments, &continuation)
      method.call(*arguments) do |result|
        unless result.is_a?(Carat::Data::ObjectInstance)
          raise Carat::CaratError, "primitive '#{name}' did not return an ObjectInstance: #{result.inspect}"
        end
        
        yield result
      end
    end
  end
end
