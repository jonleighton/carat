module Carat::Data
  class PrimitiveClass < ClassInstance
    # This is a special version of call which only dispatches primitives
    def call(method_name, argument_list = [], location = nil, &continuation)
      eval_arguments(argument_list) do |arguments|
        primitive_name = "primitive_#{method_name}"
        if current_object.respond_to?(primitive_name)
          send_primitive(primitive_name, arguments, &continuation)
        else
          raise Carat::CaratError, "undefined primitive '#{name}' for #{current_object}"
        end
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
