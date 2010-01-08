module Carat::Data
  class CaratClass < ClassInstance
    # This is a special version of call which applies only to the Carat object, and is capable
    # of invoking primitives when Carat.primitive is called.
    def call(method_name, argument_list = Carat::AST::ArgumentList.new)
      if method_name == :primitive
        call_primitive(argument_list)
      else
        super
      end
    end
    
    def call_primitive(argument_list)
      name = execute(argument_list)[0]
      raise Carat::CaratError, "invalid argument to Carat.primitive" unless name.is_a?(StringInstance)
      
      method_name = "primitive_#{name}"
      if current_object.respond_to?(method_name)
        result = current_object.send(method_name, *current_call.argument_objects)
        
        unless result.is_a?(Carat::Data::ObjectInstance)
          raise Carat::CaratError, "primitive '#{name}' did not return an ObjectInstance: #{result.inspect}"
        end
        
        result
      else
        raise Carat::CaratError, "undefined primitive '#{name}' for #{current_object}"
      end
    end
  end
end
