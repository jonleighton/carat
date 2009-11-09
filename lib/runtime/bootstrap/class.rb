module Carat::Runtime::Bootstrap
  module Class
    module ClassPrimitives
    end
    
    module ObjectPrimitives
      def new(*args)
        object = Carat::Runtime::Object.new(runtime, self)
        object.primitive_initialize(*args)
        object
      end
    end
  end
end
