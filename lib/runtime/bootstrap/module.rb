module Carat::Runtime::Bootstrap
  module Module
    module SingletonPrimitives
    end
    
    module Primitives
      def primitive_include(mod)
        self.super = Carat::Runtime::IncludeClass.new(runtime, mod, self.super)
      end
      
      def ancestors
        runtime.constants[:Array].primitive_new(*ancestors)
      end
      
      def inspect
        name.to_s
      end
    end
  end
end
