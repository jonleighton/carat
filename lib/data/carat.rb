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
      current_scope[:self].send("primitive_#{name}", *current_call.argument_objects)
    end
  end
end
