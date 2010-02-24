module Carat::Data
  class PrimitiveClass < ClassInstance
    def lookup_instance_method(name)
      primitive_name = "primitive_#{name}"
      current_object.method(primitive_name) if current_object.respond_to?(primitive_name)
    end
    
    private
    
      def create_call(method, argument_list, location, continuation)
        Carat::Runtime::PrimitiveCall.new(runtime, method, argument_list, continuation)
      end
  end
end
