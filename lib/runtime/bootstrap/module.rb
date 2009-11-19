module Carat::Runtime::Bootstrap
  module Module
    module SingletonPrimitives
    end
    
    module Primitives
      def primitive_include(mod)
        self.super = Carat::Runtime::IncludeClass.new(runtime, mod, self.super)
      end
    end
  end
end
