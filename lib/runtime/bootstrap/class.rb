module Carat::Runtime::Bootstrap
  module Class
    module SingletonPrimitives
    end
    
    module Primitives
      def new(*args)
        object = Carat::Runtime::Object.new(runtime, self)
        object.call(:initialize, args)
        object
      end
    end
  end
end
