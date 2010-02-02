module Carat::Data
  class PrimitiveClass < ClassInstance
    def has_instance_method?(name)
      current_object.respond_to?("primitive_#{name}")
    end
    
    # This is a special version of call which only dispatches primitives
    def call(method_name, argument_list = [], location = nil, &continuation)
      eval_arguments(argument_list) do |arguments|
        send_primitive("primitive_#{method_name}", arguments, &continuation)
      end
    end
    
    def eval_arguments(argument_list, &continuation)
      if argument_list.is_a?(Array)
        yield argument_list
      else
        argument_list.eval_in_scope(current_scope, &continuation)
      end
    end
    
    def send_primitive(name, arguments, &continuation)
      current_object.send(name, *arguments) do |result|
        unless result.is_a?(Carat::Data::ObjectInstance)
          raise Carat::CaratError, "primitive '#{name}' did not return an ObjectInstance: #{result.inspect}"
        end
        
        yield result
      end
    end
  end
end
