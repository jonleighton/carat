module Carat::Runtime::Bootstrap
  module Object
    module SingletonPrimitives
    end
    
    module Primitives
      # The method "initialize" has a special meaning in Ruby (obviously), so we have manually
      # prefixed it here
      def primitive_initialize
        # Do nothing by default
      end
    end
  end
end
